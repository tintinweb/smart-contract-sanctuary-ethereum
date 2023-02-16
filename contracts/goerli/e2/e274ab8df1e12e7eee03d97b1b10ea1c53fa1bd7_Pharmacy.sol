pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Pharmacy is AccessControl{
    using SafeMath for uint256;
    using SafeMath for uint144;
    using SafeMath for uint32;

    /// @dev The contract deployer is assigned the DEFAULT_ADMIN_ROLE as per AccessControl.sol
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    bytes32 public constant PRESCRIBER_ROLE = keccak256("PRESCRIBER_ROLE");

    /// @dev Modifier to restrict access to accounts that DEFAULT_ADMIN_ROLE has granted the PRESCRIBER_ROLE
    modifier onlyPrescriber() {
      require(hasRole(PRESCRIBER_ROLE, msg.sender), "You are not a prescriber");
      _;
    }

    /// @dev Modifier to restrict access to DEFAULT_ADMIN_ROLE
    modifier onlyAdmin() {
      require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You are not a pharmacy admin");
      _;
    }

    /// @dev Modifier to check that a prescriptionId is valid as a function input
    /// @param _prescriptionId The prescription ID number
    modifier isPrescriptionValid(uint256 _prescriptionId) {
      require(prescriptionCount >= _prescriptionId, "This prescription doesn't exist yet");
      require(scripts[_prescriptionId].prescriptionValid == true, "This script is invalid");
      require(scripts[_prescriptionId].dispensed == false, "This prescription has already been purchased");
      _;
    }
    
    event NewScript(uint256 indexed prescriptionId, address indexed patient, string indexed medication);
    event ScriptCancelled(uint256 indexed prescriptionId);
    event ScriptEdited(uint256 indexed prescriptionId);
    event ScriptDispensed(uint256 indexed prescriptionId, address indexed patient, string indexed medication);

    /// @dev struct to represent a script
    struct Script { 
        uint256 prescriptionId;
        address prescriber;
        address patient;
        string medication; // Tried declaring as a "bytes32" first, but decided it was simpler for the dev and user experience to use "string", even if gas costs are higher
        // Pack the following variables into a single 256-bit storage slot
        uint32 timePrescribed; // uses single storage slot - 32 bits
        uint32 timeDispensed; // uses single storage slot - 32 bits
        bool prescriptionValid; // uses single storage slot - 8 bits
        bool dispensed; // uses single storage slot - 8 bits
        uint32 dose; // uses single storage slot - 32 bits
        uint144 price; // uses single storage slot - 144 bits
        // 32 + 32 + 8 + 8 + 32 + 144 = 256 bits 
        string instructions; // Store unit, repeats, quantity, indication, route here
    }

    /// @dev For a public array of structs, Solidity has a limitation of 12 properties or else it calls a "Stack Too Deep" error
    Script[] private scripts;

    uint public prescriptionCount; //How many total prescriptions are there?
    mapping(address => uint256) private prescriberActivePrescriptionCount; //How many active prescriptions does a prescriber have?
    mapping(address => uint256) private patientActivePrescriptionCount; //How many active prescriptions does a patient have?
    mapping(address => uint256[]) private prescriberPrescriptions; //What presciptions has this prescriber created?
    mapping(address => uint256[]) private patientPrescriptions; //What prescriptions has this patient been prescribed?
  
    /* PRESCRIBER FUNCTIONS */

    /** @notice Create a prescription - PRESCRIBER ONLY
      * @param _patient Patient address
      * @param _medication Medication as a string
      * @param _dose Dose
      * @param _instructions Prescription instructions as a string
      * @return uint256 Returns the prescriptionId of the newly created prescription
      */
    function createPrescription(
        address _patient, 
        string memory _medication,
        uint32 _dose,
        string memory _instructions
        ) public onlyPrescriber returns (uint256) {
            require (msg.sender != _patient, "You are not allowed to prescribe for yourself");

            uint256 prescriptionId = prescriptionCount++;

            scripts.push(Script(
                prescriptionId,
                msg.sender,
                _patient,
                _medication,
                uint32(block.timestamp), 
                0, //If I declare 0 here, is it a uint32 or a uint256?
                true,
                false,
                _dose,
                10**16, // Set default price of 0.01 ETH, deciding price mechanism for later
                _instructions
            ));

            prescriberActivePrescriptionCount[msg.sender]++;
            patientActivePrescriptionCount[_patient]++;
            prescriberPrescriptions[msg.sender].push(prescriptionId);
            patientPrescriptions[_patient].push(prescriptionId);

            emit NewScript(prescriptionId, _patient, _medication);

            return prescriptionId;
        }

    /** @notice Cancel a prescription - CAN ONLY BE USED BY THE PRESCRIBER FOR THEIR OWN CREATED PRESCRIPTIONS
      * @param _prescriptionId Prescription ID number
      * @return bool Return 'true' if the function is successful
      */
    function cancelPrescription(uint256 _prescriptionId) public onlyPrescriber isPrescriptionValid(_prescriptionId) returns (bool) {
      require(scripts[_prescriptionId].prescriber == msg.sender, "You did not create this prescription");
      scripts[_prescriptionId].prescriptionValid = false;
      patientActivePrescriptionCount[scripts[_prescriptionId].patient]--;
      prescriberActivePrescriptionCount[scripts[_prescriptionId].prescriber]--;
      emit ScriptCancelled(_prescriptionId);
      return true;
    }

    /** @notice Edit a prescription - CAN ONLY BE USED BY THE PRESCRIBER FOR THEIR OWN CREATED AND ACTIVE PRESCRIPTIONS
      * @param _prescriptionId Prescription ID number of the script we want to edit
      * @param _medication What we want to change the medication to
      * @param _dose What we want to change the medication to
      * @param _dose What we want to change the dose to
      * @param _instructions What we want to change the instructions to
      * @return bool Return 'true' if the function is successful
      */
    function editPrescription(
        uint256 _prescriptionId,
        string memory _medication,
        uint32 _dose,
        string memory _instructions
        ) public onlyPrescriber isPrescriptionValid(_prescriptionId) returns (bool) {
      require(scripts[_prescriptionId].prescriber == msg.sender, "You did not create this prescription");
      
      scripts[_prescriptionId].medication = _medication;
      scripts[_prescriptionId].dose = _dose;
      scripts[_prescriptionId].instructions = _instructions;

      emit ScriptEdited(_prescriptionId); 

      return true;
    }

    /* GETTER FUNCTIONS */

    /** @notice Get the details for a specific script
      * @dev Starting in Solidity 0.8.0, functions can return structs
      * @param _prescriptionId Prescription ID number of the script we want details for
      * @return struct Script with corresponding prescription ID
      */
    function getScriptInformation(uint256 _prescriptionId) public view returns (Script memory) {
        require(hasRole(PRESCRIBER_ROLE, msg.sender) || msg.sender == scripts[_prescriptionId].patient || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You are not allowed to view this script");
        return scripts[_prescriptionId];
    }

    /** @notice Get the number of active scripts for a prescriber - A prescriber can only call this for themselves
      * @param _prescriber Prescriber address
      * @return prescriptionCount
      */
    function get_prescriberActivePrescriptionCount(address _prescriber) public view returns (uint256 prescriptionCount) {
      require(hasRole(PRESCRIBER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You are not allowed to use this getter function");  
      require(msg.sender == _prescriber, "You can only see your own prescription count");
      prescriptionCount = prescriberActivePrescriptionCount[_prescriber];
    }

    /** @notice Get the number of active scripts for a patient - A patient can only call this themselves
      * @param _patient Patient address
      * @return prescriptionCount
      */
    function get_patientActivePrescriptionCount(address _patient) public view returns (uint256 prescriptionCount) {
      require(hasRole(PRESCRIBER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == _patient, "You are not allowed to use this getter function");  
      prescriptionCount = patientActivePrescriptionCount[_patient];
    }

    // We allow prescribers only to see their own prescriptions, or the DEFAULT_ADMIN_ROLE

    /** @notice Get the scripts that a prescriber has created - A prescriber can only call this for themselves, and patients cannot use this function
      * @param _prescriber Prescriber address
      * @return prescriptionIds Dynamic array containing prescription IDs that the prescriber was created
      */
    function get_prescriberPrescriptions(address _prescriber) public view returns (uint256[] memory prescriptionIds) {
      require(hasRole(PRESCRIBER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You are not allowed to use this getter function");  
      require(msg.sender == _prescriber, "You can only see your own prescription count");
      prescriptionIds = prescriberPrescriptions[_prescriber];
    }

    /** @notice Get the scripts that a prescriber has created - A prescriber can only call this for themselves, and patients cannot use this function
      * @param _patient Patient address
      * @return prescriptionIds Dynamic array containing prescription IDs of the scripts that the patient has been assigned
      */
    function get_patientPrescriptions(address _patient) public view returns (uint256[] memory prescriptionIds) {
      require(hasRole(PRESCRIBER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == _patient, "You are not allowed to use this getter function");  
      prescriptionIds = patientPrescriptions[_patient];
    }

    /* PATIENT FUNCTIONS */

    /** @notice Purchase a script - requires sending ETH as payment
      * @param _prescriptionId Prescription ID of the script we want to purchase
      * @return bool true if the function is successful
      */
    function purchase (uint256 _prescriptionId) payable public isPrescriptionValid(_prescriptionId) returns (bool) {
      require(msg.sender == scripts[_prescriptionId].patient, "This is not your script");
      require(msg.value >= scripts[_prescriptionId].price, "You did not pay enough");

      scripts[_prescriptionId].timeDispensed = uint32(block.timestamp);
      scripts[_prescriptionId].prescriptionValid = false;
      scripts[_prescriptionId].dispensed = true;

      emit ScriptDispensed(_prescriptionId, scripts[_prescriptionId].patient, scripts[_prescriptionId].medication);

      return true;
    }

    /* PHARMACY ADMIN FUNCTIONS */

    /** @notice Withdraw ETH from the Pharmacy smart contract
      * @param _amount Amount of ETH desired for withdrawal
      */
    function withdrawFunds (uint256 _amount) external onlyAdmin {
        require(address(this).balance >= _amount);
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /** @notice Send ETH from the Pharmacy smart contract to a desired address
      * @param _target Desired target address for sending funds
      * @param _amount Amount of ETH desired to send
      */
    function sendFunds (address _target, uint256 _amount) external onlyAdmin {
        require(address(this).balance >= _amount);
        (bool success, ) = _target.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /* BACKDOOR FUNCTIONS FOR BOOTCAMP ASSESSMENT PURPOSES */

    /** @notice Become a prescriber
      * @dev This function is only included for demonstration purposes so the assessor can have easy access to both the prescriber and patient UIs
      * @dev This function should be deleted for actual use
      * @dev We are using _setupRole() outside of the constructor function, which is circumventing the admin system imposed by AccessControl.sol
      */
    function becomePrescriber() public {
        _setupRole(PRESCRIBER_ROLE, msg.sender);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}