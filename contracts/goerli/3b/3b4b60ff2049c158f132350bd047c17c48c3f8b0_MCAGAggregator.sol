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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {Errors} from "src/libraries/Errors.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {MCAGAggregatorInterface} from "src/interfaces/MCAGAggregatorInterface.sol";
import {Roles} from "./libraries/Roles.sol";

contract MCAGAggregator is MCAGAggregatorInterface {
    uint8 private constant _VERSION = 1;
    uint8 private constant _DECIMALS = 27;

    IAccessControl public immutable accessController;

    uint80 private _roundId;
    string private _description;
    int256 private _answer;
    int256 private _maxAnswer;
    uint256 private _updatedAt;

    modifier onlyRole(bytes32 role) {
        if (!accessController.hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    /**
     * @param description_ Description of the oracle - for example "10 YEAR US TREASURY".
     * @param maxAnswer_ Maximum sensible answer the contract should accept.
     * @param _accessController MCAG AccessController.
     */
    constructor(string memory description_, int256 maxAnswer_, IAccessControl _accessController) {
        if (address(_accessController) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        _description = description_;
        _maxAnswer = maxAnswer_;
        accessController = _accessController;
    }

    /**
     * @notice Transmits a new price to the aggreator and updates the answer, round id and updated at.
     * @dev Can only be called by a registered transmitter.
     * @param answer New central bank rate as a per second cumualtive rate in 27 decimals.
     * For example a 5% annual linear rate would be converted to a per second cumulative rate as follow :
     * (1 + 5%)^(1 / 31536000) * 1e27 = 100000000578137865680459171
     */
    function transmit(int256 answer) external override onlyRole(Roles.MCAG_TRANSMITTER_ROLE) {
        if (answer > _maxAnswer) {
            revert Errors.TRANSMITTED_ANSWER_TOO_HIGH(answer, _maxAnswer);
        }

        ++_roundId;
        _updatedAt = block.timestamp;
        _answer = answer;

        emit AnswerTransmitted(msg.sender, _roundId, answer);
    }

    /**
     * @notice Sets a new max answer.
     * @dev Can only be called by MCAG Manager.
     * @param newMaxAnswer New maximum sensible answer the contract should accept.
     */
    function setMaxAnswer(int256 newMaxAnswer) external onlyRole(Roles.MCAG_MANAGER_ROLE) {
        emit MaxAnswerSet(_maxAnswer, newMaxAnswer);
        _maxAnswer = newMaxAnswer;
    }

    /**
     * @notice Returns round data per the Chainlink format.
     * @return roundId Latest _roundId.
     * @return answer Latest answer transmitted.
     * @return startedAt Unused variable here only to follow Chainlink format.
     * @return updatedAt Timestamp of the last transmitted answer.
     * @return answeredInRound Latest _roundId.
     */
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = _roundId;
        answer = _answer;
        updatedAt = _updatedAt;
        answeredInRound = _roundId;
    }

    /**
     * @return Description of the oracle - for example "10 YEAR US TREASURY".
     */
    function description() external view override returns (string memory) {
        return _description;
    }

    /**
     * @return Maximum sensible answer the contract should accept.
     */
    function maxAnswer() external view override returns (int256) {
        return _maxAnswer;
    }

    /**
     * @return Number of decimals used to get its user representation.
     */
    function decimals() external pure override returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @return Contract version.
     */
    function version() external pure override returns (uint8) {
        return _VERSION;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface MCAGAggregatorInterface {
    event AnswerTransmitted(address indexed transmitter, uint80 roundId, int256 answer);
    event MaxAnswerSet(int256 oldMaxAnswer, int256 newMaxAnswer);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function maxAnswer() external view returns (int256);

    function version() external view returns (uint8);

    function transmit(int256 answer) external;

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library Errors {
    error CANNOT_SET_TO_ADDRESS_ZERO();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
    error ERC721_APPROVAL_TO_CURRENT_OWNER();
    error ERC721_APPROVE_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED_FOR_ALL();
    error ERC721_INVALID_TOKEN_ID();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER();
    error ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(address account, bytes32 role);
    error BLACKLISTABLE_CALLER_IS_NOT_BLACKLISTER();
    error BLACKLISTABLE_ACCOUNT_IS_BLACKLISTED(address account);
    error TRANSMITTED_ANSWER_TOO_HIGH(int256 answer, int256 maxAnswer);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library Roles {
    bytes32 public constant MCAG_MINT_ROLE = keccak256("MCAG_MINT_ROLE");
    bytes32 public constant MCAG_BURN_ROLE = keccak256("MCAG_BURN_ROLE");
    bytes32 public constant MCAG_BLACKLIST_ROLE = keccak256("MCAG_BLACKLIST_ROLE");
    bytes32 public constant MCAG_PAUSE_ROLE = keccak256("MCAG_PAUSE_ROLE");
    bytes32 public constant MCAG_UNPAUSE_ROLE = keccak256("MCAG_UNPAUSE_ROLE");
    bytes32 public constant MCAG_TRANSMITTER_ROLE = keccak256("MCAG_TRANSMITTER_ROLE");
    bytes32 public constant MCAG_MANAGER_ROLE = keccak256("MCAG_MANAGER_ROLE");
}