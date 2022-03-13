// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract NFBOracle is Ownable, AccessControl, Pausable {
    /**
     * @dev Source of truth for all calculations. Index of the bracket represents the match starting from 0 up to 66. The element is the winning team from that match.
     * TODO might need to have a different approach. We need to think of a way to calculate correct result for each bracket in `calcBracketPoints`. We could not be using the `roundIndex`
     * as it gets updated after each round and its not reliable. Might need to have another state variable which indicates for a certain match index how many points are granted
     */

    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    address public nfbRouter;
    uint16[] public bracketResults; // Array of `n` elements representing the winner from the past rounds.
    uint8[] public roundIndexes; // Array of indexes from where each round starts.
    uint8 public bracketLength; // Number representing the required length for the bracket.
    uint8 public round; // Starts from 1. Updated after each round has finished.
    uint8 public roundIndex; // Starts from 1. Updated after each round has finished, serves as multiplier for getting the points for each bracket and as divider for getting the winners for each round.
    uint8 public tournamentStage; // Divided by `roundIndex` for getting the winners for each round.
    uint8 public constant START = 0;
    uint8 public constant END = 1;
    // round => (startRound => endRound)
    mapping(uint8 => mapping(uint8 => uint256)) public roundsBounds;

    event LogNFBRouterSet(address triggeredBy, address newAddress);
    event LogRoundUpdated(address from, uint8 newRound, uint8 newRoundIndex);
    event LogRoundReverted(address from, uint8 newRound, uint8 newRoundIndex);
    event LogBracketResultsUpdated(address from, uint16[] bracketResults);
    event LogSetRoundBounds(uint8 round, uint256 startRound, uint256 endRound);
    event LogContractsUnpaused(address triggeredBy);

    constructor(
        uint8 _tournamentStage,
        uint8 _bracketLength,
        uint8[] memory _roundIndexes
    ) {
        round = 1;
        roundIndex = 1;
        bracketResults = new uint16[](_bracketLength);
        tournamentStage = _tournamentStage;
        bracketLength = _bracketLength;
        roundIndexes = _roundIndexes;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); //todo default admin of the contract might be different than the deployer. Let's coordinate this
        _setupRole(UPDATER_ROLE, _msgSender());
    }

    modifier onlyFromNFBRouter() {
        require(msg.sender == nfbRouter, "NFBO: Invalid call");
        _;
    }

    modifier onlyMatchingLengths(uint16[] memory bracket) {
        require(bracket.length == bracketLength, "NFBO: lengths don't match");
        _;
    }

    /**
     * @dev Setter for the `nfbRouter`
     * @param _nfbRouter NFBRouter contract address
     * * Requirements:
     *
     * - only owner of the contract can call.
     *
     * Emits {LogNFBRouterSet} event.
     */
    function setNFBRouter(address _nfbRouter) external onlyOwner {
        require(
            _nfbRouter != address(0),
            "NFBO: NFBRouter can't be zero address"
        );
        nfbRouter = _nfbRouter;
        emit LogNFBRouterSet(msg.sender, _nfbRouter);
    }

    /**
     * @dev Sets start and end timestamp of the current round.
     * @param startRound uint256 representing the start of the current round
     * @param endRound uint256 representing the end of the current round
     * Requirements:
     *
     * - `startRound` must be passed.
     * - `endRound` must be passed.
     * -  only owner of the contract can call.
     *
     * Emits a {LogSetRoundBounds} event.
     */
    function setRoundBounds(
        uint8 roundToSet,
        uint256 startRound,
        uint256 endRound
    ) public onlyRole(UPDATER_ROLE) {
        // require(roundToSet >= 1 && roundToSet <= 6, "NFBO: Invalid round");
        // require(startRound > block.timestamp, "NFBO: Invalid start round");
        // require(startRound < endRound, "NFBO: Invalid end round");
        // require(
        //     roundToSet == 1 || startRound > roundsBounds[roundToSet - 1][1], // if not in first round, check whether start of the current round is higher than the end of previous
        //     "NFBO: Invalid round params"
        // );

        roundsBounds[roundToSet][START] = startRound;
        roundsBounds[roundToSet][END] = endRound;

        emit LogSetRoundBounds(roundToSet, startRound, endRound);
    }

    /**
     * @dev Updates the score multiplier, used for calculation of points for a correct prediction. Score multiplier is updated after each round finishes.
     * Requirements:
     *
     * - only owner of the contract can call.
     *
     * Emits a {LogRoundUpdated} event.
     */
    function updateRound() external whenNotPaused onlyRole(UPDATER_ROLE) {
        require(round < roundIndexes.length, "NFBO: already in last round");

        round++;
        roundIndex *= 2;

        emit LogRoundUpdated(msg.sender, round, roundIndex);
    }

    /**
     * @dev Triggered by an external service so we get the correct sports data
     * @param _newBracketResults - used to override current `bracketResults` with the most up to date state of the tournament.
     * Requirements:
     *
     * - only owner of the contract can call.
     *
     * Emits a {LogBracketResultsUpdated} event.
     */
    function updateBracketResults(uint16[] memory _newBracketResults)
        external
        whenNotPaused
        onlyRole(UPDATER_ROLE)
        onlyMatchingLengths(_newBracketResults)
    {
        bracketResults = _newBracketResults;

        emit LogBracketResultsUpdated(msg.sender, _newBracketResults);
    }

    //compare to the matches[], where we have a match update the score by increasing it with roundIndex.
    /**
     * @dev Calculates a given bracket result by comparing it to the latest state of the tournament from `bracketResults`. When 2 elements positioned at the same index are equal, points are added.
     * @param bracket - which we are going to calculate the result against.
     * @return `bracketPoints` and `roundPoints` respectively the total points for the bracket and the points generated through the round.
     * Requirements:
     *
     * `bracket` length should be equal to `bracketLength`
     */
    function calcBracketPoints(uint16[] memory bracket)
        public
        view
        onlyMatchingLengths(bracket)
        onlyMatchingLengths(bracketResults)
        returns (uint8, uint8)
    {
        uint8 bracketPoints = 0;
        uint8 roundPoints = 0;
        uint8 currentRound = 0;
        uint8 currentRoundIndex = 1;

        for (uint256 i = 0; i < round; i++) {
            uint8 startIndex = roundIndexes[currentRound];
            uint8 roundWinners = tournamentStage / currentRoundIndex;
            uint8 currentActiveRound = round - 1;
            for (uint8 k = 0; k < roundWinners; k++) {
                if (bracket[startIndex + k] != bracketResults[startIndex + k]) {
                    continue;
                }

                bracketPoints += currentRoundIndex;

                if (i == currentActiveRound) {
                    roundPoints += currentRoundIndex;
                }
            }

            currentRound += 1;
            currentRoundIndex *= 2;
        }

        return (bracketPoints, roundPoints);
    }

    /**
     * @dev Calculates a given bracket points which are lost due to lost match in previous round.
     * @param bracket - which we are going to calculate the points lost against.
     * @return bracketPoints
     * Requirements:
     *
     * `bracket` length should be equal to `bracketLength`
     */
    function calcPointsWillBeLost(uint16[] memory bracket)
        public
        view
        onlyMatchingLengths(bracket)
        returns (uint8)
    {
        if (round == 1 || round == roundIndexes.length) {
            return 0; // Return 0 points if we are in the first or last round
        }

        uint8 pointsLost = 0;
        uint8 startIndex = roundIndexes[round - 2];
        uint8 roundWinners = tournamentStage / (roundIndex / 2);

        for (uint8 i = startIndex; i < startIndex + roundWinners; i++) {
            if (bracket[i] == bracketResults[i]) {
                continue;
            }

            uint8 currentActiveRound = round - 1;
            uint8 currActiveRoundIndex = roundIndex;

            for (uint8 k = currentActiveRound; k < roundIndexes.length; k++) {
                uint8 currStartIndex = roundIndexes[currentActiveRound];
                uint8 currRoundWinners = tournamentStage / currActiveRoundIndex;

                for (uint8 j = 0; j < currRoundWinners; j++) {
                    if (bracket[currStartIndex + j] == bracket[i]) {
                        pointsLost += currActiveRoundIndex;
                    }
                }

                currentActiveRound += 1;
                currActiveRoundIndex *= 2;
            }
        }

        return pointsLost;
    }

    /**
     * @dev Get potentially the highest possible score which this bracket is able to accumulate based on it's current result and how many winning teams in the bracket have left in the tournament
     * @param bracket array of matches that are going to be evaluated
     * @return bracketPoints highest possible score which this bracket is able to accumulate
     */
    function getBracketPotential(uint16[] memory bracket)
        external
        view
        onlyMatchingLengths(bracket)
        returns (uint16)
    {
        uint16 maxPointsTournament = 192;

        if (round == 1) {
            return maxPointsTournament; // Return max points of 192 if first round hasn't started or results aren't updated.
        }
        if (round == 6) {
            (uint8 bracketPoints, ) = calcBracketPoints(bracket);

            return bracketPoints; // Return the points which the bracket has generated in the last round.
        }

        uint8 roundToCalculateFrom = bracketResults[roundIndexes[round - 1]] ==
            0
            ? round
            : round + 1;

        (uint8 bracketPoints, ) = calcBracketPoints(bracket);
        uint16 pointsWillBeLost = calcPointsWillBeLost(bracket); // Points which will be lost from teams which have lost earlier than expected in the tournament.
        uint16 maxPointsPrevRounds = (roundToCalculateFrom - 1) * 32; // Multiply max points of each round (32) by the rounds passed.
        uint16 pointsLostPrevRounds = maxPointsPrevRounds - bracketPoints;

        return maxPointsTournament - pointsLostPrevRounds - pointsWillBeLost;
    }

    /**
     * @dev this functions is intended to never be used, but as we heavily rely on live scores we'd need an emergency function on how to revert back the round,
     * in order to correctly emit all scores from the round we are currently in. As the rounds are being updated automatically, we have to have an approach to revert
     * in case of a mistake in a live event, or if an event is completed after the predicted end of the round has ended.
     */
    function revertRoundInEmergency() public onlyRole(UPDATER_ROLE) whenPaused {
        require(round > 1, "NFBO: still in first round");

        round -= 1;
        roundIndex /= 2;

        emit LogRoundReverted(msg.sender, round, roundIndex);
    }

    /**
     * @dev Pauses NFBOracle contract.
     * Requirements:
     *
     * - must be called by the NFBRouter contract
     *
     */
    function pause() external onlyFromNFBRouter {
        _pause();
    }

    /**
     * @dev Unpauses NFBOracle contract.
     * Requirements:
     *
     * - must be called by the NFBRouter contract
     *
     */
    function unpause() external onlyFromNFBRouter {
        _unpause();
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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