/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder2/scaling-chainsaw/smart-contract/contracts/ElectionFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder2/scaling-chainsaw/smart-contract/contracts/ElectionFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

////import "./IERC165.sol";

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
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder2/scaling-chainsaw/smart-contract/contracts/ElectionFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder2/scaling-chainsaw/smart-contract/contracts/ElectionFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder2/scaling-chainsaw/smart-contract/contracts/ElectionFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder2/scaling-chainsaw/smart-contract/contracts/ElectionFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

////import "./IAccessControl.sol";
////import "../utils/Context.sol";
////import "../utils/Strings.sol";
////import "../utils/introspection/ERC165.sol";

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




/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder2/scaling-chainsaw/smart-contract/contracts/ElectionFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: Unlicense
pragma solidity ^0.8.0;

/// @title Election factory Interface
/// @author Team-d
/// @notice The contract deploys the election contract while keeping metadata about the contract

interface IElectionFactory {
    function updateElectionStatus(uint256 _electionId, string memory _status) external;
}



/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder2/scaling-chainsaw/smart-contract/contracts/ElectionFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: Unlicense
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Election factory contract
/// @author Team-d
/// @dev The contract extends the AccessControl contract by overriding the revokeRole and 
/// @dev renounceRole methods with checks to meet the needed behaviour

contract ElectionAccessControl is AccessControl {
    /// @dev Declares and initialises various roles
    bytes32 public constant CHAIRMAN_ROLE = keccak256("CHAIRMAN_ROLE");
    bytes32 public constant DIRECTOR_ROLE = keccak256("DIRECTOR_ROLE");
    bytes32 public constant TEACHER_ROLE = keccak256("TEACHER_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");

    event RenounceRole(address indexed previousChairman, address indexed newChairman);

    constructor(address _owner) {
        /// @dev Creates the role admins for different roles
        super._setRoleAdmin(STUDENT_ROLE, TEACHER_ROLE);
        super._setRoleAdmin(TEACHER_ROLE, CHAIRMAN_ROLE);
        super._setRoleAdmin(DIRECTOR_ROLE, CHAIRMAN_ROLE);
        super._setRoleAdmin(CHAIRMAN_ROLE, CHAIRMAN_ROLE);

        /// @dev Assigns the Director role to a user
        super._grantRole(DIRECTOR_ROLE, _owner);
        /// @dev Assigns the Chairman role to a user
        super._grantRole(CHAIRMAN_ROLE, _owner);
    }

    /**
     * @dev Revokes `role` from the calling account and adds a new account to the role. 
     * @dev It is only open to the CHAIRMAN_ROLE
     *
     * @dev The new account should be that of a director.
     */
    function renounceRole(bytes32 _role, address _account) public override onlyRole(CHAIRMAN_ROLE) {
        require(_role == CHAIRMAN_ROLE, "Only the chairman role can be renounced.");

        if(!super.hasRole(DIRECTOR_ROLE, _account)) {
            revert("The address for the new chairman is not a director yet");
        }

        super._grantRole(CHAIRMAN_ROLE, _account);

        super._revokeRole(CHAIRMAN_ROLE, msg.sender);

        emit RenounceRole(msg.sender, _account);
    }

    /**
     * @dev Revokes `role` from `account` except the chairman role.
     */
    function revokeRole(bytes32 _role, address _account) public override onlyRole(getRoleAdmin(_role)) {
        if(super.hasRole(CHAIRMAN_ROLE, _account)) {
            revert('Chairman role cannot be revoked');
        }

       super._revokeRole(_role, _account);
    }
}



/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder2/scaling-chainsaw/smart-contract/contracts/ElectionFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder2/scaling-chainsaw/smart-contract/contracts/ElectionFactory.sol
*/
            
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

////import '@openzeppelin/contracts/security/Pausable.sol';
////import './ElectionAccessControl.sol';
////import "./interfaces/IElectionFactory.sol";

contract Election is Pausable, ElectionAccessControl{

    string position;
    uint256 public noOfpartcipate;
    string[] public contestantsName;
    bool public electionStatus;
    bool public resultStatus;

    /// @dev Timestamps for when the election started and ended
    uint256 public startAt;
    uint256 public endAt;
    uint256 public resultReadyAt;

    /// @notice Election status
    string constant private PENDING = 'Pending';
    string constant private STARTED = 'Started';
    string constant private ENDED = 'Ended';
    string constant private RESULTS_READY = 'Results ready';

    uint256 immutable index;
    address immutable electionFactory;

    error NoOfParticatantNotMatchingParticipateName();
    error AlreadyVoted();
    error ResultNotYetRelease();
    error AccessDenied();
    error VotingNotAllowed();
    error VotingNotStarted();
    error VotingEnd();

    struct Candidates {
        string candidatesName;
        uint256 voteCount;
    }

    mapping(address => bool) voterStatus;
    mapping(string => Candidates) candidates;
    mapping(string => uint256) voteCount;
    Candidates[] results;

    /// ======================= MODIFIERS =================================
    ///@notice modifier to specify that election has not ended
    modifier electionHasEnded() {
        require(startAt > endAt, "Sorry, the Election has ended!");
        _;
    }
    ///@notice modifier to check that election is active
    modifier electionIsActive() {
        require(startAt > 0 , "Election has not begun!");
        _;
    }
    
    modifier allRole() {
        require(
            hasRole(CHAIRMAN_ROLE, msg.sender) == true || 
            hasRole(TEACHER_ROLE, msg.sender) == true || 
            hasRole(STUDENT_ROLE, msg.sender) == true || 
            hasRole(DIRECTOR_ROLE, msg.sender) == true, "ACCESS DENIED");
        _;
    }

    modifier onlyChairmanAndTeacherRole () {
        require(
            hasRole(CHAIRMAN_ROLE, msg.sender) == true || 
            hasRole(TEACHER_ROLE, msg.sender) == true, 
            "ACCESS FOR TEACHER(s) AND CHAIRMAN ONLY" );
        _;
    }

    modifier onlyChairmanAndTeacherAndDirectorRole() {
        require(
            hasRole(CHAIRMAN_ROLE, msg.sender) == true || 
            hasRole(TEACHER_ROLE, msg.sender) == true || 
            hasRole(DIRECTOR_ROLE,msg.sender) == true, 
            "ACCESS FOR TEACHER(s) AND CHAIRMAN ONLY" );
        _;
    }

    ///======================= EVENTS ==============================
    ///@notice event to emit when election has ended
    event ElectionEnded(uint256[] _winnerIds, uint256 _winnerVoteCount);
    event SetUpTeacher(address[] teacher);
    event RegisterTeacher(address[] student);
    event SetUpDirector(address[] director);
    event Vote(string candidates, address voter);
    event StartVoting(uint256 startAt);
    event EndVoting(uint256 endAt);
    event SetUpBOD(address[] _Bod);
    event RegisterStudent(address[] _student);

    constructor(
        address _owner,
        string memory _position,
        uint256 _noOfParticipants,
        string[] memory _contestants,
        uint256 _index, 
        address _electionFactory
    ) ElectionAccessControl(_owner) {
        if (_noOfParticipants != _contestants.length)
            revert NoOfParticatantNotMatchingParticipateName();

        position = _position;
        noOfpartcipate = _noOfParticipants;
        contestantsName = _contestants;
        index = _index;
        electionFactory = _electionFactory;

        for (uint256 i = 0; i < _contestants.length; i++) {
            Candidates storage _candidates = candidates[_contestants[i]];
            _candidates.candidatesName = _contestants[i];
        }
    }


/// @notice setup teachers
/// @dev only CHAIRMAN_ROLE can call this method
/// @param _teacher array of address
    function setupTeachers(
        address[] memory _teacher)
        onlyRole(CHAIRMAN_ROLE)
        public returns(bool){
        for(uint i = 0; i < _teacher.length; i++){
            grantRole(TEACHER_ROLE, _teacher[i]);
        }
        emit SetUpTeacher(_teacher);
        return true;
    }


    /// @notice registers student
    /// @dev only TEACHER_ROLE can call this method
    /// @param _student array of address
    function registerStudent(address[] memory _student)
        public 
        onlyRole(TEACHER_ROLE) 
        returns(bool)
    {
        for(uint i = 0; i < _student.length; i++){
            grantRole(STUDENT_ROLE, _student[i]);
        }
        emit RegisterStudent(_student);
        return true;
        
    }


    /// @notice setup directors
    /// @dev only CHAIRMAN_ROLE can call this method
    /// @param _Bod array of address
    function setupBOD(address[] memory _Bod) 
        public 
        onlyRole(CHAIRMAN_ROLE)
        returns(bool)
    {
        for(uint i = 0; i < _Bod.length; i < i++){
            grantRole(DIRECTOR_ROLE, _Bod[i]);
        }
        emit SetUpBOD(_Bod);
        return true;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - only CHAIRMAN_ROLE can call this method
     */
    function pause() external onlyRole(CHAIRMAN_ROLE) returns(bool){
        _pause();
        return true;
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     * - only CHAIRMAN_ROLE can call this method
     */
    function unpause() external onlyRole(CHAIRMAN_ROLE) returns(bool){
        _unpause();
        return true;
    }

    /// @notice Ensures that voting begins
    function enableVoting() external onlyRole(CHAIRMAN_ROLE) {
         startAt = block.timestamp;

         _updateStatusOnFactory(STARTED);

        emit StartVoting(block.timestamp);
    }

    /// @notice for voting
    /// @dev allRole can call this function
    /// @param _participantsName a string
    function vote(string memory _participantsName)
        public allRole() 
        electionIsActive
        electionHasEnded
        whenNotPaused 
        returns(bool)
    {
        if(voterStatus[msg.sender] == true) revert AlreadyVoted();
        uint currentVote = voteCount[_participantsName];
        voteCount[_participantsName] = currentVote + 1;
        voterStatus[msg.sender] = true;

        emit Vote(_participantsName, msg.sender);
        return true;
    }

    function disableVoting() external onlyRole(CHAIRMAN_ROLE) {
        if(endAt == startAt)
            revert VotingNotStarted();

        endAt = block.timestamp;

        _updateStatusOnFactory(ENDED);

        emit EndVoting(block.timestamp);
    }

    /// @notice for compiling vote
    /// @dev only CHAIRMAN_ROLE and TEACHER_ROLE can call this function
    function compileResult() 
        public 
        onlyChairmanAndTeacherRole() 
        returns(Candidates[] memory)
    {
        for(uint i = 0; i < contestantsName.length; i++){
            Candidates storage _candidates = candidates[contestantsName[i]];
            _candidates.voteCount = voteCount[contestantsName[i]];
            results.push(_candidates);
        }
        return results;
    }


    /// @notice for making result public
    /// @dev allrole except STUDENT_ROLE can call this function
    function showResult() onlyChairmanAndTeacherAndDirectorRole() public returns(bool){
        resultStatus = true;

        _updateStatusOnFactory(RESULTS_READY);

        resultReadyAt = block.timestamp;

        return true;
    }

    /// @notice for viewing results
    /// @dev resultStatus must be true to view the result
    function result() public view returns(Candidates[] memory){
        if(resultStatus == false) revert ResultNotYetRelease();
        return results;
    }

    /// @notice for privateViewing results
    /// @dev allRole except STUDENT_ROLE can call this method
    function privateViewResult()  public view onlyChairmanAndTeacherAndDirectorRole()returns(Candidates[] memory){
        return results;
    }

    /// @dev Makes call to the election factory to update the status of an election.
    function _updateStatusOnFactory(string memory _status) internal {
        IElectionFactory(electionFactory).updateElectionStatus(index, _status);
    }
}


/** 
 *  SourceUnit: /home/pelumi/Desktop/WorkFolder2/scaling-chainsaw/smart-contract/contracts/ElectionFactory.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: Unlicense
pragma solidity ^0.8.0;

////import "./Election.sol";

/// @title Election factory contract
/// @author Team-d
/// @notice The contract deploys the election contract while keeping metadata about the contract

contract ElectionFactory {
    address public owner;

    struct ElectionDetails {
        uint256 id;
        address electionAddress;
        string position;
        string[] contestants;
        uint256 createdAt;
        string status;
    }
    ElectionDetails[] private elections;
    
    /// @notice Number of elections conducted
    uint256 public electionCount;

    /// @notice Election status
    string constant private PENDING = 'Pending';
    string constant private STARTED = 'Started';
    string constant private ENDED = 'Ended';
    string constant private RESULTS_READY = 'Results ready';

    event SetOwner(address indexed oldOwner, address indexed newOwner);
    event CreateElection(uint256 id, address electionAddress, address indexed creator, string position);
    event UpdateElectionStatus(string status, address electionAddress);

    error NotAuthorised(address caller);
    error UnAuthorizedElectionContract(address electionContract);
    error BadStatusRequest(string status);
    
    constructor() {
        owner = msg.sender;
    }

    /// @dev Ensures that only the owner can call a function
    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert NotAuthorised(msg.sender);
        }
        _;
    }

    /// @dev Sets a new owner
    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(msg.sender, _owner);
    }

    /// @dev Deploys a new election smart contract and stores the details.
    function createElection(string memory _position, string[] memory _contestants) external onlyOwner{
        uint256 count = electionCount;
        count++;

        Election election = new Election(msg.sender, _position, _contestants.length, _contestants, count, address(this));
        
        ElectionDetails memory electionDetail;

        electionDetail.id = count;
        electionDetail.electionAddress = address(election);
        electionDetail.position = _position;
        electionDetail.contestants = _contestants;
        electionDetail.createdAt = block.timestamp;
        electionDetail.status = PENDING;

        elections.push(electionDetail);

        electionCount = count;

        emit CreateElection(count, address(election), msg.sender, _position);
    }

    /// @dev Called from the election contract to update the status of an election
    function updateElectionStatus(uint256 _electionId, string memory _status) external {
        ElectionDetails memory electionDetails = elections[_electionId - 1];

        if(electionDetails.electionAddress != msg.sender) {
            revert UnAuthorizedElectionContract(msg.sender);
        }

        electionDetails.status = _status;

        elections[_electionId - 1] = electionDetails;

        emit UpdateElectionStatus(_status, electionDetails.electionAddress);
    }
    
    /// @dev Sends a list of election parameters
    function getElections (uint256 _start, uint256 _length) 
        external 
        view 
        returns(
            address [] memory electionAddress, 
            string [] memory position,
            uint256 [] memory createdAt,
            string[] memory status 
        )
    {
        require(_start > 0, "Caller cannot start from zero start from one");
        
        uint256 electionsLength = elections.length;
        uint256 end = _start + _length;

        if(electionsLength < end){
            _length = (electionsLength - _start) + 1;
            end = electionsLength + 1;
        }

        electionAddress = new address[] (_length);
        position = new string[] (_length);
        createdAt = new uint256[](_length);
        status = new string[] (_length);

        uint256 counter = 0;

        for (uint256 i = _start; i < end; i++){
            ElectionDetails memory election = elections[i-1];

            electionAddress[counter] = election.electionAddress;
            position[counter] = election.position;
            createdAt[counter] = election.createdAt;
            status[counter] = election.status;

            counter++;
        }

        return (electionAddress, position, createdAt, status);
    }
}