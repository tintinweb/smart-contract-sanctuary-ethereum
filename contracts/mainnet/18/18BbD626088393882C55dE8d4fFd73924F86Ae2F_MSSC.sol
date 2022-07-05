//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./lib/SSCVault.sol";
import "./lib/Assertions.sol";

contract MSSC is SSCVault, AccessControl {
    // Events
    event RegisterCycle(bytes32 indexed cycleId, Instruction[] instructions);
    event ExecuteCycle(bytes32 indexed cycleId, bytes32[] instructions);

    bytes32 public constant MEMBRANE_ROLE = keccak256("MEMBRANE");

    mapping(bytes32 => SettlementCycle) private _cycles;
    mapping(bytes32 => Instruction) private _instructions;

    constructor() payable {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MEMBRANE_ROLE, _msgSender());
    }

    /**
     * @notice Register settlementCycle, this function can only be perfomed by a Membrane wallet.
     *         Caller must transform obfuscatedId string to bytes32, pure strings are not supported.
     *
     * @param cycleId Cycle's bytes32 obfuscatedId to register.
     * @param instructions instructions to register.
     */
    function registerSettlementCycle(
        bytes32 cycleId,
        Instruction[] calldata instructions
    ) external onlyRole(MEMBRANE_ROLE) {
        _assertCycleDoesNotExist(cycleId);
        // Retrieve the total number of instructions and place on the stack.
        uint256 totalInstructions = instructions.length;

        if (totalInstructions == 0) {
            revert CycleHasNoInstruction();
        }

        bytes32[] storage newInstructions = _cycles[cycleId].instructions;

        for (uint256 i = 0; i < totalInstructions; ) {
            Instruction memory instruction = instructions[i];
            bytes32 instructionId = instruction.id;

            _assertValidInstruction(instruction);

            newInstructions.push(instructionId);
            _instructions[instructionId] = instruction;

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }

        emit RegisterCycle(cycleId, instructions);
    }

    /**
     * @notice Execute instructions in a SettlementCycle, anyone can call this function as long as it
     *         meets some requirements.
     *
     * @param cycleId Cycle's bytes32 obfuscatedId to execute.
     */
    function executeInstructions(bytes32 cycleId) external {
        _assertCycleExists(cycleId);

        _assertCycleIsNotExecuted(cycleId);

        _cycles[cycleId].executed = true;
        bytes32[] memory instructions = _cycles[cycleId].instructions;

        // Retrieve the total number of instructions and place on the stack.
        uint256 totalInstructions = instructions.length;

        for (uint256 i = 0; i < totalInstructions; ) {
            Instruction memory instruction = _instructions[instructions[i]];

            DepositItem memory depositItem = _buildDepositItem(instruction);

            _withdrawTo(depositItem, instruction.receiver);

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
        emit ExecuteCycle(cycleId, instructions);
    }

    /**
     * @notice Make deposits (Native coin or ERC20 tokens) to a existent instruction, {msg.sender} will become
     *         the {sender} of the instruction hence will be the only account which is able to withdraw
     *         those allocated funds.
     *
     * @param instructionId Instruction to allocate funds.
     */
    function deposit(bytes32 instructionId) external payable {
        Instruction memory instruction = _instructions[instructionId];
        uint256 amount = instruction.amount;
        // Ensure that instruction does exist by checking its amount.
        if (amount == 0) {
            revert NoInstruction(instructionId);
        }

        DepositItem memory depositItem = _buildDepositItem(instruction);

        _deposit(depositItem, amount);
    }

    /**
     * @notice Withdraw funds from a settlement. Caller must be the sender of instruction.
     *
     * @param instructionId Instruction to withdraw deposited funds from.
     */
    function withdraw(bytes32 instructionId) external {
        DepositItem memory depositItem = _buildDepositItem(
            _instructions[instructionId]
        );
        _withdraw(depositItem);
    }

    /**
     * @notice View function to get the instructions ids in a settlement cycle.
     *
     * @param cycleId Cycle to check.
     */
    function getSettlementInstructions(bytes32 cycleId)
        external
        view
        returns (bytes32[] memory)
    {
        _assertCycleExists(cycleId);
        return _cycles[cycleId].instructions;
    }

    /**
     * @notice View function to check if a cycle has been registered.
     *
     * @param cycleId Cycle to check.
     */
    function registered(bytes32 cycleId) external view returns (bool) {
        return _exist(cycleId);
    }

    /**
     * @notice View function to check if a cycle has been executed.
     *
     * @param cycleId Cycle to check.
     */
    function executed(bytes32 cycleId) external view returns (bool) {
        _assertCycleExists(cycleId);
        return _cycles[cycleId].executed;
    }

    /**
     * @notice View function to get deposited funds to an instruction.
     *
     * @param instructionId Instruction to get deposited funds from.
     */
    function deposits(bytes32 instructionId) external view returns (uint256) {
        return _deposits[instructionId];
    }

    /**
     * @notice View function to get sender of a instruction.
     *
     * @param instructionId Instruction to get the sender.
     */
    function senderOf(bytes32 instructionId) external view returns (address) {
        return _senderOf[instructionId];
    }

    /*//////////////////////////////////////////////////////////////
                             ASSERTIONS
    //////////////////////////////////////////////////////////////*/

    // Check if an address is a sender of any instruction in the instruction.

    // Ensure that {cycleId} is registered.
    function _assertCycleExists(bytes32 cycleId) private view {
        if (!_exist(cycleId)) {
            revert NoCycle();
        }
    }

    // Ensure that {cycleId} is NOT registered.
    function _assertCycleDoesNotExist(bytes32 cycleId) private view {
        if (_exist(cycleId)) {
            revert CycleAlreadyRegistered();
        }
    }

    // Ensure that cycle hasn't been executed before.
    function _assertCycleIsNotExecuted(bytes32 cycleId) private view {
        if (_cycles[cycleId].executed) {
            revert CycleAlreadyExecuted();
        }
    }

    // Validate Instruction
    function _assertValidInstruction(Instruction memory instruction)
        private
        view
    {
        // Ensure that instruction doesn't exist by checking its amount.
        if (_instructions[instruction.id].amount > 0) {
            revert InstructionExists(instruction.id);
        }

        _assertValidInstructionData(instruction);
    }

    // Check that cycleId is registered by looking at instructions length, this function may change its logic later
    function _exist(bytes32 cycleId) private view returns (bool) {
        return _cycles[cycleId].instructions.length > 0;
    }

    // Build Deposit item from instruction
    function _buildDepositItem(Instruction memory instruction)
        private
        pure
        returns (DepositItem memory)
    {
        return
            DepositItem({
                depositType: instruction.asset == address(0)
                    ? DepositType.NATIVE
                    : DepositType.ERC20,
                token: instruction.asset,
                instructionId: instruction.id
            });
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

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

import "./SSCStructs.sol";
import "./Assertions.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";

/**
 * @title  Vault
 * @notice Vault contains logic for making deposits and withdrawals of funds
 *         to and from Settlements.
 */
contract SSCVault is Assertions {
    using SafeTransferLib for ERC20;

    // Events
    event Deposit(address indexed account, bytes32 instruction);
    event Withdraw(address indexed account, bytes32 instruction);

    // Track allocated funds to various instructions.
    mapping(bytes32 => uint256) internal _deposits;

    // Track sender of instruction
    mapping(bytes32 => address) internal _senderOf;

    /**
     * @notice Internal function to deposit and allocate funds to a instruction.
     *
     * @param item Contains data of the item to deposit.
     * @param instructionAmount Amount to deposit, if {item.depositType} is ETH, this
     *        parameter MUST be {msg.value}.
     */
    function _deposit(DepositItem memory item, uint256 instructionAmount)
        internal
    {
        _assertNonZeroAmount(instructionAmount, item.instructionId);
        _assertInstructionHasNoDeposits(item.instructionId);

        _deposits[item.instructionId] = instructionAmount;
        _senderOf[item.instructionId] = msg.sender;

        if (item.depositType == DepositType.ERC20) {
            ERC20(item.token).safeTransferFrom(
                msg.sender,
                address(this),
                instructionAmount
            );
        } else {
            if (msg.value != instructionAmount) {
                revert InvalidSuppliedETHAmount(item.instructionId);
            }
        }
        emit Deposit(msg.sender, item.instructionId);
    }

    /**
     * @notice Internal function to withdraw funds from an instruction to {msg.sender}.
     *
     * @param item Contains data of the item to withdraw.
     */
    function _withdraw(DepositItem memory item) internal {
        _assertAccountIsSender(msg.sender, item.instructionId);

        _withdrawTo(item, msg.sender);

        emit Withdraw(msg.sender, item.instructionId);
    }

    /**
     * @notice Internal to transfer allocated funds to a given account.
     *
     * @param item Contains data of the item to withdraw.
     * @param to Recipient of the withdrawal.
     */
    function _withdrawTo(DepositItem memory item, address to) internal {
        uint256 amount = _deposits[item.instructionId];
        _assertInstructionHasDeposits(item.instructionId);

        // empty deposited funds
        _deposits[item.instructionId] = 0;

        if (item.depositType == DepositType.ERC20) {
            ERC20(item.token).safeTransfer(to, amount);
        } else {
            SafeTransferLib.safeTransferETH(to, amount);
        }
    }

    // Ensure that an account is a sender of the instruction.
    function _assertAccountIsSender(address account, bytes32 instructionId)
        private
        view
    {
        // Revert if {account} is not sender.
        if (_senderOf[instructionId] != account) {
            revert NotASender(instructionId);
        }
    }

    // Ensure that required amount in a instruction is fullfiled.
    function _assertInstructionHasDeposits(bytes32 instructionId) private view {
        // Revert if the supplied amount is equal to zero.
        if (_deposits[instructionId] == 0) {
            revert NoDeposits(instructionId);
        }
    }

    // Ensure that required amount in a instruction is fullfiled.
    function _assertInstructionHasNoDeposits(bytes32 instructionId)
        private
        view
    {
        // Revert if the supplied amount is not equal to zero.
        if (_deposits[instructionId] != 0) {
            revert AlreadyDeposited(instructionId);
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/MSSCErrors.sol";
import "./SSCStructs.sol";

/**
 * @title Assertions
 * @notice Assertions contains logic for making various assertions that do not
 *         fit neatly within a dedicated semantic scope.
 */
contract Assertions is MSSCErrors {
    /**
     * @dev Internal view function to ensure that a given instruction tuple has valid data.
     *
     * @param instruction  The instruction tuple to check.
     */

    function _assertValidInstructionData(Instruction memory instruction)
        internal
        view
    {
        _assertNonZeroAmount(instruction.amount, instruction.id);

        _assertReceiverIsNotZeroAddress(instruction);

        _assertValidAsset(instruction);
    }

    /**
     * @dev Internal pure function to ensure that a given item amount is not
     *      zero.
     *
     * @param amount The amount to check.
     */
    function _assertNonZeroAmount(uint256 amount, bytes32 instructionId) internal pure {
        // Revert if the supplied amount is equal to zero.
        if (amount == 0) {
            revert ZeroAmount(instructionId);
        }
    }

    /**
     * @dev Internal view function to ensure that {sender} and {recipient} in a given
     *      instruction are non-zero addresses.
     *
     * @param instruction  The instruction tuple to check.
     */
    function _assertReceiverIsNotZeroAddress(Instruction memory instruction)
        private
        pure
    {
        if (instruction.receiver == address(0)) {
            revert ReceiverIsZeroAddress(instruction.id);
        }
    }

    /**
     * @dev Internal view function to ensure that {asset} is a valid contract or null address
     *      for ETH transfers.
     *
     * @param instruction  The instruction tuple to check.
     */
    function _assertValidAsset(Instruction memory instruction) private view {
        if (
            instruction.asset.code.length <= 0 &&
            instruction.asset != address(0)
        ) {
            revert InvalidAsset(instruction.id);
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./SSCEnums.sol";

struct Instruction {
    bytes32 id;
    address receiver;
    address asset;
    uint256 amount;
}

struct SettlementCycle {
    bytes32[] instructions;
    bool executed;
}

struct DepositItem {
    DepositType depositType;
    bytes32 instructionId;
    address token;
}

struct TransferDepositedItem {
    DepositItem depositItem;
    address to;
    uint256 amount;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

enum DepositType {
    NATIVE,
    ERC20
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/**
 * @title MSSCErrors
 */
interface MSSCErrors {
    /**
     * @dev Revert with an error when trying to register an existent Settlement Cycle.
     */
    error CycleAlreadyRegistered();

    /**
     * @dev Revert with an error when executing a previously executed Settlement Cycle.
     */
    error CycleAlreadyExecuted();

    /**
     * @dev Revert with an error when attempting to interact with a cycle that
     *      does not yet exist.
     */
    error NoCycle();

    /**
     * @dev Revert with an error when attempting to register a cycle without a
     *      single instruction.
     */
    error CycleHasNoInstruction();

    /**
     * @dev Revert with an error when trying to register an existent instruction.
     *
     * @param instruction The instruction that already exists.
     *
     */
    error InstructionExists(bytes32 instruction);

    /**
     * @dev Revert with an error when attempting to interact with an instruction that
     *      does not yet exist.
     *
     * @param instruction The instruction that doesn't exist.
     */
    error NoInstruction(bytes32 instruction);

    /**
     * @dev Revert with an error when an asset of a instruction is invalid.
     *
     * @param instruction The instruction that contain the invalid asset.
     */
    error InvalidAsset(bytes32 instruction);

    /**
     * @dev Revert with an error when attempting to register a receiver account
     *      and supplying the null address.
     *
     * @param instruction The instruction that contain the zero address.
     */
    error ReceiverIsZeroAddress(bytes32 instruction);

    /**
     * @dev Revert with an error when invalid ether is deposited for an instruction.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error InvalidSuppliedETHAmount(bytes32 instruction);

    /**
     * @dev Revert with an error when an account is not a sender the instruction.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error NotASender(bytes32 instruction);

    /**
     * @dev Revert with an error when attempting to register a Settlement with no amount.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error ZeroAmount(bytes32 instruction);

    /**
     * @dev Revert with an error when a instruction has no deposits.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error NoDeposits(bytes32 instruction);

    /**
     * @dev Revert with an error when a instruction has deposits.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error AlreadyDeposited(bytes32 instruction);
}