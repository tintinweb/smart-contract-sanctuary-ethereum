// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/extensions/GovernorCountingSimple.sol)

pragma solidity ^0.8.0;

import "../Governor.sol";

/**
 * @dev Extension of {Governor} for simple, 3 options, vote counting.
 *
 * _Available since v4.3._
 */
abstract contract GovernorCountingSimple is Governor {
    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        return (proposalVote.againstVotes, proposalVote.forVotes, proposalVote.abstainVotes);
    }

    /**
     * @dev See {Governor-_quorumReached}.
     */
    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return quorum(proposalSnapshot(proposalId)) <= proposalVote.forVotes + proposalVote.abstainVotes;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return proposalVote.forVotes > proposalVote.againstVotes;
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal virtual override {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        require(!proposalVote.hasVoted[account], "GovernorVotingSimple: vote already cast");
        proposalVote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalVote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalVote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalVote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorSettings.sol)

pragma solidity ^0.8.0;

import "../Governor.sol";

/**
 * @dev Extension of {Governor} for settings updatable through governance.
 *
 * _Available since v4.4._
 */
abstract contract GovernorSettings is Governor {
    uint256 private _votingDelay;
    uint256 private _votingPeriod;
    uint256 private _proposalThreshold;

    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);

    /**
     * @dev Initialize the governance parameters.
     */
    constructor(
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold
    ) {
        _setVotingDelay(initialVotingDelay);
        _setVotingPeriod(initialVotingPeriod);
        _setProposalThreshold(initialProposalThreshold);
    }

    /**
     * @dev See {IGovernor-votingDelay}.
     */
    function votingDelay() public view virtual override returns (uint256) {
        return _votingDelay;
    }

    /**
     * @dev See {IGovernor-votingPeriod}.
     */
    function votingPeriod() public view virtual override returns (uint256) {
        return _votingPeriod;
    }

    /**
     * @dev See {Governor-proposalThreshold}.
     */
    function proposalThreshold() public view virtual override returns (uint256) {
        return _proposalThreshold;
    }

    /**
     * @dev Update the voting delay. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingDelaySet} event.
     */
    function setVotingDelay(uint256 newVotingDelay) public virtual onlyGovernance {
        _setVotingDelay(newVotingDelay);
    }

    /**
     * @dev Update the voting period. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function setVotingPeriod(uint256 newVotingPeriod) public virtual onlyGovernance {
        _setVotingPeriod(newVotingPeriod);
    }

    /**
     * @dev Update the proposal threshold. This operation can only be performed through a governance proposal.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function setProposalThreshold(uint256 newProposalThreshold) public virtual onlyGovernance {
        _setProposalThreshold(newProposalThreshold);
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {VotingDelaySet} event.
     */
    function _setVotingDelay(uint256 newVotingDelay) internal virtual {
        emit VotingDelaySet(_votingDelay, newVotingDelay);
        _votingDelay = newVotingDelay;
    }

    /**
     * @dev Internal setter for the voting period.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function _setVotingPeriod(uint256 newVotingPeriod) internal virtual {
        // voting period must be at least one block long
        require(newVotingPeriod > 0, "GovernorSettings: voting period too low");
        emit VotingPeriodSet(_votingPeriod, newVotingPeriod);
        _votingPeriod = newVotingPeriod;
    }

    /**
     * @dev Internal setter for the proposal threshold.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function _setProposalThreshold(uint256 newProposalThreshold) internal virtual {
        emit ProposalThresholdSet(_proposalThreshold, newProposalThreshold);
        _proposalThreshold = newProposalThreshold;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import "../Governor.sol";
import "../utils/IVotes.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotes is Governor {
    IVotes public immutable token;

    constructor(IVotes tokenAddress) {
        token = tokenAddress;
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        return token.getPastVotes(account, blockNumber);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/extensions/GovernorVotesQuorumFraction.sol)

pragma solidity ^0.8.0;

import "./GovernorVotes.sol";
import "../../utils/Checkpoints.sol";
import "../../utils/math/SafeCast.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token and a quorum expressed as a
 * fraction of the total supply.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotesQuorumFraction is GovernorVotes {
    using Checkpoints for Checkpoints.History;

    uint256 private _quorumNumerator; // DEPRECATED
    Checkpoints.History private _quorumNumeratorHistory;

    event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

    /**
     * @dev Initialize quorum as a fraction of the token's total supply.
     *
     * The fraction is specified as `numerator / denominator`. By default the denominator is 100, so quorum is
     * specified as a percent: a numerator of 10 corresponds to quorum being 10% of total supply. The denominator can be
     * customized by overriding {quorumDenominator}.
     */
    constructor(uint256 quorumNumeratorValue) {
        _updateQuorumNumerator(quorumNumeratorValue);
    }

    /**
     * @dev Returns the current quorum numerator. See {quorumDenominator}.
     */
    function quorumNumerator() public view virtual returns (uint256) {
        return _quorumNumeratorHistory._checkpoints.length == 0 ? _quorumNumerator : _quorumNumeratorHistory.latest();
    }

    /**
     * @dev Returns the quorum numerator at a specific block number. See {quorumDenominator}.
     */
    function quorumNumerator(uint256 blockNumber) public view virtual returns (uint256) {
        // If history is empty, fallback to old storage
        uint256 length = _quorumNumeratorHistory._checkpoints.length;
        if (length == 0) {
            return _quorumNumerator;
        }

        // Optimistic search, check the latest checkpoint
        Checkpoints.Checkpoint memory latest = _quorumNumeratorHistory._checkpoints[length - 1];
        if (latest._blockNumber <= blockNumber) {
            return latest._value;
        }

        // Otherwise, do the binary search
        return _quorumNumeratorHistory.getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the quorum denominator. Defaults to 100, but may be overridden.
     */
    function quorumDenominator() public view virtual returns (uint256) {
        return 100;
    }

    /**
     * @dev Returns the quorum for a block number, in terms of number of votes: `supply * numerator / denominator`.
     */
    function quorum(uint256 blockNumber) public view virtual override returns (uint256) {
        return (token.getPastTotalSupply(blockNumber) * quorumNumerator(blockNumber)) / quorumDenominator();
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - Must be called through a governance proposal.
     * - New numerator must be smaller or equal to the denominator.
     */
    function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyGovernance {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - New numerator must be smaller or equal to the denominator.
     */
    function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
        require(
            newQuorumNumerator <= quorumDenominator(),
            "GovernorVotesQuorumFraction: quorumNumerator over quorumDenominator"
        );

        uint256 oldQuorumNumerator = quorumNumerator();

        // Make sure we keep track of the original numerator in contracts upgraded from a version without checkpoints.
        if (oldQuorumNumerator != 0 && _quorumNumeratorHistory._checkpoints.length == 0) {
            _quorumNumeratorHistory._checkpoints.push(
                Checkpoints.Checkpoint({_blockNumber: 0, _value: SafeCast.toUint224(oldQuorumNumerator)})
            );
        }

        // Set new quorum for future proposals
        _quorumNumeratorHistory.push(newQuorumNumerator);

        emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/IGovernorTimelock.sol)

pragma solidity ^0.8.0;

import "../IGovernor.sol";

/**
 * @dev Extension of the {IGovernor} for timelock supporting modules.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorTimelock is IGovernor {
    event ProposalQueued(uint256 proposalId, uint256 eta);

    function timelock() public view virtual returns (address);

    function proposalEta(uint256 proposalId) public view virtual returns (uint256);

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/Governor.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";
import "../token/ERC1155/IERC1155Receiver.sol";
import "../utils/cryptography/ECDSA.sol";
import "../utils/cryptography/EIP712.sol";
import "../utils/introspection/ERC165.sol";
import "../utils/math/SafeCast.sol";
import "../utils/structs/DoubleEndedQueue.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";
import "../utils/Timers.sol";
import "./IGovernor.sol";

/**
 * @dev Core of the governance system, designed to be extended though various modules.
 *
 * This contract is abstract and requires several function to be implemented in various modules:
 *
 * - A counting module must implement {quorum}, {_quorumReached}, {_voteSucceeded} and {_countVote}
 * - A voting module must implement {_getVotes}
 * - Additionanly, the {votingPeriod} must also be implemented
 *
 * _Available since v4.3._
 */
abstract contract Governor is Context, ERC165, EIP712, IGovernor, IERC721Receiver, IERC1155Receiver {
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;
    using SafeCast for uint256;
    using Timers for Timers.BlockNumber;

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");
    bytes32 public constant EXTENDED_BALLOT_TYPEHASH =
        keccak256("ExtendedBallot(uint256 proposalId,uint8 support,string reason,bytes params)");

    struct ProposalCore {
        Timers.BlockNumber voteStart;
        Timers.BlockNumber voteEnd;
        bool executed;
        bool canceled;
    }

    string private _name;

    mapping(uint256 => ProposalCore) private _proposals;

    // This queue keeps track of the governor operating on itself. Calls to functions protected by the
    // {onlyGovernance} modifier needs to be whitelisted in this queue. Whitelisting is set in {_beforeExecute},
    // consumed by the {onlyGovernance} modifier and eventually reset in {_afterExecute}. This ensures that the
    // execution of {onlyGovernance} protected calls can only be achieved through successful proposals.
    DoubleEndedQueue.Bytes32Deque private _governanceCall;

    /**
     * @dev Restricts a function so it can only be executed through governance proposals. For example, governance
     * parameter setters in {GovernorSettings} are protected using this modifier.
     *
     * The governance executing address may be different from the Governor's own address, for example it could be a
     * timelock. This can be customized by modules by overriding {_executor}. The executor is only able to invoke these
     * functions during the execution of the governor's {execute} function, and not under any other circumstances. Thus,
     * for example, additional timelock proposers are not able to change governance parameters without going through the
     * governance protocol (since v4.6).
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "Governor: onlyGovernance");
        if (_executor() != address(this)) {
            bytes32 msgDataHash = keccak256(_msgData());
            // loop until popping the expected operation - throw if deque is empty (operation not authorized)
            while (_governanceCall.popFront() != msgDataHash) {}
        }
        _;
    }

    /**
     * @dev Sets the value for {name} and {version}
     */
    constructor(string memory name_) EIP712(name_, version()) {
        _name = name_;
    }

    /**
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     */
    receive() external payable virtual {
        require(_executor() == address(this));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        // In addition to the current interfaceId, also support previous version of the interfaceId that did not
        // include the castVoteWithReasonAndParams() function as standard
        return
            interfaceId ==
            (type(IGovernor).interfaceId ^
                this.castVoteWithReasonAndParams.selector ^
                this.castVoteWithReasonAndParamsBySig.selector ^
                this.getVotesWithParams.selector) ||
            interfaceId == type(IGovernor).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }

    /**
     * @dev See {IGovernor-hashProposal}.
     *
     * The proposal id is produced by hashing the ABI encoded `targets` array, the `values` array, the `calldatas` array
     * and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
     * can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
     * advance, before the proposal is submitted.
     *
     * Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
     * same proposal (with same operation and same description) will have the same id if submitted on multiple governors
     * across multiple networks. This also means that in order to execute the same operation twice (on the same
     * governor) the proposer will have to change the description in order to avoid proposal id conflicts.
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    /**
     * @dev See {IGovernor-state}.
     */
    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        ProposalCore storage proposal = _proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        uint256 snapshot = proposalSnapshot(proposalId);

        if (snapshot == 0) {
            revert("Governor: unknown proposal id");
        }

        if (snapshot >= block.number) {
            return ProposalState.Pending;
        }

        uint256 deadline = proposalDeadline(proposalId);

        if (deadline >= block.number) {
            return ProposalState.Active;
        }

        if (_quorumReached(proposalId) && _voteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    /**
     * @dev See {IGovernor-proposalSnapshot}.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart.getDeadline();
    }

    /**
     * @dev See {IGovernor-proposalDeadline}.
     */
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd.getDeadline();
    }

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Get the voting weight of `account` at a specific `blockNumber`, for a vote as described by `params`.
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) internal view virtual returns (uint256);

    /**
     * @dev Register a vote for `proposalId` by `account` with a given `support`, voting `weight` and voting `params`.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory params
    ) internal virtual;

    /**
     * @dev Default additional encoded parameters used by castVote methods that don't include them
     *
     * Note: Should be overridden by specific implementations to use an appropriate value, the
     * meaning of the additional params, in the context of that implementation
     */
    function _defaultParams() internal view virtual returns (bytes memory) {
        return "";
    }

    /**
     * @dev See {IGovernor-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        require(
            getVotes(_msgSender(), block.number - 1) >= proposalThreshold(),
            "Governor: proposer votes below proposal threshold"
        );

        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        require(targets.length == values.length, "Governor: invalid proposal length");
        require(targets.length == calldatas.length, "Governor: invalid proposal length");
        require(targets.length > 0, "Governor: empty proposal");

        ProposalCore storage proposal = _proposals[proposalId];
        require(proposal.voteStart.isUnset(), "Governor: proposal already exists");

        uint64 snapshot = block.number.toUint64() + votingDelay().toUint64();
        uint64 deadline = snapshot + votingPeriod().toUint64();

        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);

        emit ProposalCreated(
            proposalId,
            _msgSender(),
            targets,
            values,
            new string[](targets.length),
            calldatas,
            snapshot,
            deadline,
            description
        );

        return proposalId;
    }

    /**
     * @dev See {IGovernor-execute}.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        ProposalState status = state(proposalId);
        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued,
            "Governor: proposal not successful"
        );
        _proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);

        _beforeExecute(proposalId, targets, values, calldatas, descriptionHash);
        _execute(proposalId, targets, values, calldatas, descriptionHash);
        _afterExecute(proposalId, targets, values, calldatas, descriptionHash);

        return proposalId;
    }

    /**
     * @dev Internal execution mechanism. Can be overridden to implement different execution mechanism
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    }

    /**
     * @dev Hook before execution is triggered.
     */
    function _beforeExecute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory, /* values */
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            for (uint256 i = 0; i < targets.length; ++i) {
                if (targets[i] == address(this)) {
                    _governanceCall.pushBack(keccak256(calldatas[i]));
                }
            }
        }
    }

    /**
     * @dev Hook after execution is triggered.
     */
    function _afterExecute(
        uint256, /* proposalId */
        address[] memory, /* targets */
        uint256[] memory, /* values */
        bytes[] memory, /* calldatas */
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            if (!_governanceCall.empty()) {
                _governanceCall.clear();
            }
        }
    }

    /**
     * @dev Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * canceled to allow distinguishing it from executed proposals.
     *
     * Emits a {IGovernor-ProposalCanceled} event.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        ProposalState status = state(proposalId);

        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Governor: proposal not active"
        );
        _proposals[proposalId].canceled = true;

        emit ProposalCanceled(proposalId);

        return proposalId;
    }

    /**
     * @dev See {IGovernor-getVotes}.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return _getVotes(account, blockNumber, _defaultParams());
    }

    /**
     * @dev See {IGovernor-getVotesWithParams}.
     */
    function getVotesWithParams(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) public view virtual override returns (uint256) {
        return _getVotes(account, blockNumber, params);
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason);
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParams}.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason, params);
    }

    /**
     * @dev See {IGovernor-castVoteBySig}.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))),
            v,
            r,
            s
        );
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParamsBySig}.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSA.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        EXTENDED_BALLOT_TYPEHASH,
                        proposalId,
                        support,
                        keccak256(bytes(reason)),
                        keccak256(params)
                    )
                )
            ),
            v,
            r,
            s
        );

        return _castVote(proposalId, voter, support, reason, params);
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function. Uses the _defaultParams().
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual returns (uint256) {
        return _castVote(proposalId, account, support, reason, _defaultParams());
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason,
        bytes memory params
    ) internal virtual returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 weight = _getVotes(account, proposal.voteStart.getDeadline(), params);
        _countVote(proposalId, account, support, weight, params);

        if (params.length == 0) {
            emit VoteCast(account, proposalId, support, weight, reason);
        } else {
            emit VoteCastWithParams(account, proposalId, support, weight, reason, params);
        }

        return weight;
    }

    /**
     * @dev Relays a transaction or function call to an arbitrary target. In cases where the governance executor
     * is some contract other than the governor itself, like when using a timelock, this function can be invoked
     * in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake.
     * Note that if the executor is simply the governor itself, use of `relay` is redundant.
     */
    function relay(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable virtual onlyGovernance {
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        Address.verifyCallResult(success, returndata, "Governor: relay reverted without message");
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/IGovernor.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/ERC165.sol";

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernor is IERC165 {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast without params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    /**
     * @dev Emitted when a vote is cast with params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     * `params` are additional encoded parameters. Their intepepretation also depends on the voting module used.
     */
    event VoteCastWithParams(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 weight,
        string reason,
        bytes params
    );

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
     * name that describes the behavior. For example:
     *
     * - `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
     * - `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
     * ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, or delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
     * quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber` given additional encoded parameters.
     */
    function getVotesWithParams(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns whether `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote using the user's cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters using the user's cryptographic signature.
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Checkpoints.sol)
// This file was procedurally generated from scripts/generate/templates/Checkpoints.js.

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SafeCast.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * _Available since v4.5._
 */
library Checkpoints {
    struct History {
        Checkpoint[] _checkpoints;
    }

    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Because the number returned corresponds to that at the end of the
     * block, the requested block number must be in the past, excluding the current block.
     */
    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the searched
     * checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the number of
     * checkpoints.
     */
    function getAtProbablyRecentBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;

        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - Math.sqrt(len);
            if (key < _unsafeAccess(self._checkpoints, mid)._blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);

        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * Returns previous value and new value.
     */
    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        return _insert(self._checkpoints, SafeCast.toUint32(block.number), SafeCast.toUint224(value));
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(History storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _blockNumber,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._blockNumber, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(History storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._blockNumber <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._blockNumber == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint({_blockNumber: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint({_blockNumber: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint[] storage self, uint256 pos) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace224 {
        Checkpoint224[] _checkpoints;
    }

    struct Checkpoint224 {
        uint32 _key;
        uint224 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace224 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace224 storage self,
        uint32 key,
        uint224 value
    ) internal returns (uint224, uint224) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace224 storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace224 storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _key,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint224 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace224 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint224[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint224 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._key <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint224({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint224({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint224[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint224 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace160 {
        Checkpoint160[] _checkpoints;
    }

    struct Checkpoint160 {
        uint96 _key;
        uint160 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace160 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace160 storage self,
        uint96 key,
        uint160 value
    ) internal returns (uint160, uint160) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace160 storage self) internal view returns (uint160) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace160 storage self)
        internal
        view
        returns (
            bool exists,
            uint96 _key,
            uint160 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint160 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace160 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint160[] storage self,
        uint96 key,
        uint160 value
    ) private returns (uint160, uint160) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint160 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._key <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint160({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint160({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint160[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint160 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "../math/SafeCast.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
 * used in storage, and not in memory.
 * ```
 * DoubleEndedQueue.Bytes32Deque queue;
 * ```
 *
 * _Available since v4.6._
 */
library DoubleEndedQueue {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct Bytes32Deque {
        int128 _begin;
        int128 _end;
        mapping(int128 => bytes32) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(Bytes32Deque storage deque, bytes32 value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the end of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popBack(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        value = deque._data[backIndex];
        delete deque._data[backIndex];
        deque._end = backIndex;
    }

    /**
     * @dev Inserts an item at the beginning of the queue.
     */
    function pushFront(Bytes32Deque storage deque, bytes32 value) internal {
        int128 frontIndex;
        unchecked {
            frontIndex = deque._begin - 1;
        }
        deque._data[frontIndex] = value;
        deque._begin = frontIndex;
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Returns the item at the end of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function back(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        return deque._data[backIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(Bytes32Deque storage deque, uint256 index) internal view returns (bytes32 value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCast.toInt128(int256(deque._begin) + SafeCast.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Resets the queue back to being empty.
     *
     * NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
     * out on potential gas refunds.
     */
    function clear(Bytes32Deque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(Bytes32Deque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(Bytes32Deque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Timers.sol)

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "../../lib/openzeppelin-contracts/contracts/governance/utils/IVotes.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

interface IZivoeGlobals_P_10 {
    function stZVE() external view returns (address);
}

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires accounts to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is IVotes, ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /// @notice Custom virtual function for viewing GBL (ZivoeGlobals).
    function GBL() public view virtual returns (address) {
        return address(0);
    }

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // Initially we check if the block is recent to narrow the search range.
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 length = ckpts.length;

        uint256 low = 0;
        uint256 high = length;

        if (length > 5) {
            uint256 mid = length - Math.sqrt(length);
            if (_unsafeAccess(ckpts, mid).fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(ckpts, mid).fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : _unsafeAccess(ckpts, high - 1).votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {IVotes-DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if (IZivoeGlobals_P_10(GBL()).stZVE() == address(0) || (to != IZivoeGlobals_P_10(GBL()).stZVE() && from != IZivoeGlobals_P_10(GBL()).stZVE())) {
            _moveVotingPower(delegates(from), delegates(to), amount);
        }
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {IVotes-DelegateChanged} and {IVotes-DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator) + IERC20(IZivoeGlobals_P_10(GBL()).stZVE()).balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;

        Checkpoint memory oldCkpt = pos == 0 ? Checkpoint(0, 0) : _unsafeAccess(ckpts, pos - 1);

        oldWeight = oldCkpt.votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && oldCkpt.fromBlock == block.number) {
            _unsafeAccess(ckpts, pos - 1).votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint[] storage ckpts, uint256 pos) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, ckpts.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorTimelockControl.sol)

pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/governance/extensions/IGovernorTimelock.sol";
import "../../lib/openzeppelin-contracts/contracts/governance/Governor.sol";

import "../libraries/ZivoeTimelockController.sol";

/**
 * @dev Extension of {Governor} that binds the execution process to an instance of {ZivoeTimelockController}. This adds a
 * delay, enforced by the {ZivoeTimelockController} to all successful proposal (in addition to the voting duration). The
 * {Governor} needs the proposer (and ideally the executor) roles for the {Governor} to work properly.
 *
 * Using this model means the proposal will be operated by the {ZivoeTimelockController} and not by the {Governor}. Thus,
 * the assets and permissions must be attached to the {ZivoeTimelockController}. Any asset sent to the {Governor} will be
 * inaccessible.
 *
 * WARNING: Setting up the ZivoeTimelockController to have additional proposers besides the governor is very risky, as it
 * grants them powers that they must be trusted or known not to use: 1) {onlyGovernance} functions like {relay} are
 * available to them through the timelock, and 2) approved governance proposals can be blocked by them, effectively
 * executing a Denial of Service attack. This risk will be mitigated in a future release.
 *
 * _Available since v4.3._
 */
abstract contract ZivoeGovernorTimelockControl is IGovernorTimelock, Governor {
    ZivoeTimelockController private _timelock;
    mapping(uint256 => bytes32) private _timelockIds;

    /**
     * @dev Emitted when the timelock controller used for proposal execution is modified.
     */
    event TimelockChange(address oldTimelock, address newTimelock);

    /**
     * @dev Set the timelock.
     */
    constructor(ZivoeTimelockController timelockAddress) {
        _updateTimelock(timelockAddress);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Governor) returns (bool) {
        return interfaceId == type(IGovernorTimelock).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Overridden version of the {Governor-state} function with added support for the `Queued` status.
     */
    function state(uint256 proposalId) public view virtual override(IGovernor, Governor) returns (ProposalState) {
        ProposalState status = super.state(proposalId);

        if (status != ProposalState.Succeeded) {
            return status;
        }

        // core tracks execution, so we just have to check if successful proposal have been queued.
        bytes32 queueid = _timelockIds[proposalId];
        if (queueid == bytes32(0)) {
            return status;
        } else if (_timelock.isOperationDone(queueid)) {
            return ProposalState.Executed;
        } else if (_timelock.isOperationPending(queueid)) {
            return ProposalState.Queued;
        } else {
            return ProposalState.Canceled;
        }
    }

    /**
     * @dev Public accessor to check the address of the timelock
     */
    function timelock() public view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public accessor to check the eta of a queued proposal
     */
    function proposalEta(uint256 proposalId) public view virtual override returns (uint256) {
        uint256 eta = _timelock.getTimestamp(_timelockIds[proposalId]);
        return eta == 1 ? 0 : eta; // _DONE_TIMESTAMP (1) should be replaced with a 0 value
    }

    /**
     * @dev Function to queue a proposal to the timelock.
     */
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        require(state(proposalId) == ProposalState.Succeeded, "Governor: proposal not successful");

        uint256 delay = _timelock.getMinDelay();
        _timelockIds[proposalId] = _timelock.hashOperationBatch(targets, values, calldatas, 0, descriptionHash);
        _timelock.scheduleBatch(targets, values, calldatas, 0, descriptionHash, delay);

        emit ProposalQueued(proposalId, block.timestamp + delay);

        return proposalId;
    }

    /**
     * @dev Overridden execute function that run the already queued proposal through the timelock.
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override {
        _timelock.executeBatch{value: msg.value}(targets, values, calldatas, 0, descriptionHash);
    }

    /**
     * @dev Overridden version of the {Governor-_cancel} function to cancel the timelocked proposal if it as already
     * been queued.
     */
    // This function can reenter through the external call to the timelock, but we assume the timelock is trusted and
    // well behaved (according to ZivoeTimelockController) and this will not happen.
    // slither-disable-next-line reentrancy-no-eth
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override returns (uint256) {
        uint256 proposalId = super._cancel(targets, values, calldatas, descriptionHash);

        if (_timelockIds[proposalId] != 0) {
            _timelock.cancel(_timelockIds[proposalId]);
            delete _timelockIds[proposalId];
        }

        return proposalId;
    }

    /**
     * @dev Address through which the governor executes action. In this case, the timelock.
     */
    function _executor() internal view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public endpoint to update the underlying timelock instance. Restricted to the timelock itself, so updates
     * must be proposed, scheduled, and executed through governance proposals.
     *
     * CAUTION: It is not recommended to change the timelock while there are other queued governance proposals.
     */
    function updateTimelock(ZivoeTimelockController newTimelock) external virtual onlyGovernance {
        _updateTimelock(newTimelock);
    }

    function _updateTimelock(ZivoeTimelockController newTimelock) private {
        emit TimelockChange(address(_timelock), address(newTimelock));
        _timelock = newTimelock;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

/// @notice Specialized math functions that always return uint256 and never revert. 
///         This condenses and simplifies the codebase, for example trySub() from OpenZeppelin 
///         would have sufficed, however those returned tuples to include information 
///         about the success of the function, which is inefficient for our purposes. 
library ZivoeMath {
    
    /// @notice Returns 0 if divisions results in value less than 1, or division by zero.
    function zDiv(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;
            if (y > x) return 0;
            return (x / y);
        }
    }

    /// @notice The return value is if subtraction results in underflow.
    ///         Subtraction routine that does not revert and returns a singleton, 
    ///         making it cheaper and more suitable for composition and use as an attribute.
    ///         It was made to be a cheaper version of openZepelins trySub.
    function zSub(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y > x) return 0;
            return (x - y);
        }
    }
    
    /// @notice Returns the smallest of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/utils/Context.sol";

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
abstract contract ZivoeOwnableLocked is Context {
    
    address private _owner;

    bool public locked; /// @dev A variable "locked" that prevents future ownership transfer.

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferredAndLocked(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier unlocked() {
        require(!locked, "ZivoeOwnableLocked::unlocked() locked");
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
        require(owner() == _msgSender(), "ZivoeOwnableLocked::_checkOwner owner() != _msgSender()");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner unlocked {
        _transferOwnership(address(0));
    }

    // TODO: Consider if renounceOwnership() should still be callable if in "locked" state?

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner unlocked {
        require(newOwner != address(0), "ZivoeOwnableLocked::transferOwnership() newOwner == address(0)");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnershipAndLock(address newOwner) public virtual onlyOwner unlocked {
        require(newOwner != address(0), "ZivoeOwnableLocked::transferOwnershipAndLock() newOwner == address(0)");
        locked = true;
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
// OpenZeppelin Contracts (last updated v4.8.0) (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Address.sol";

interface IZivoeGBL_P_11 {
    function isKeeper(address) external view returns (bool);
}

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for accounts of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {ZivoeTimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract ZivoeTimelockController is AccessControl, IERC721Receiver, IERC1155Receiver {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    address public immutable GBL;  /// @dev Zivoe globals contract.

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with the following parameters:
     *
     * - `minDelay`: initial minimum delay for operations
     * - `proposers`: accounts to be granted proposer and canceller roles
     * - `executors`: accounts to be granted executor role
     * - `admin`: optional account to be granted admin role; disable with zero address
     *
     * IMPORTANT: The optional admin can aid with initial configuration of roles after deployment
     * without being subject to delay, but this role should be subsequently renounced in favor of
     * administration through timelocked proposals. Previous versions of this contract would assign
     * this admin to the deployer automatically and should be renounced as well.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address _GBL
    ) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(CANCELLER_ROLE, TIMELOCK_ADMIN_ROLE);

        GBL = _GBL;

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers and cancellers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
            _setupRole(CANCELLER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool registered) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is ready or not for a keeper.
     */
    function isOperationReadyKeeper(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp - 6 hours <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, payloads, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "ZivoeTimelockController: length mismatch");
        require(targets.length == payloads.length, "ZivoeTimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], payloads[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "ZivoeTimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "ZivoeTimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'canceller' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        require(isOperationPending(id), "ZivoeTimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function execute(
        address target,
        uint256 value,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, payload, predecessor, salt);

        if (IZivoeGBL_P_11(GBL).isKeeper(_msgSender())) {
            _beforeCallKeeper(id, predecessor);
            _execute(target, value, payload);
            emit CallExecuted(id, 0, target, value, payload);
            _afterCallKeeper(id);
        }
        else {
            _beforeCall(id, predecessor);
            _execute(target, value, payload);
            emit CallExecuted(id, 0, target, value, payload);
            _afterCall(id);
        }
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "ZivoeTimelockController: length mismatch");
        require(targets.length == payloads.length, "ZivoeTimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);

        if (IZivoeGBL_P_11(GBL).isKeeper(_msgSender())) {
            _beforeCallKeeper(id, predecessor);
            for (uint256 i = 0; i < targets.length; ++i) {
                address target = targets[i];
                uint256 value = values[i];
                bytes calldata payload = payloads[i];
                _execute(target, value, payload);
                emit CallExecuted(id, i, target, value, payload);
            }
            _afterCallKeeper(id);
        }
        else {
            _beforeCall(id, predecessor);
            for (uint256 i = 0; i < targets.length; ++i) {
                address target = targets[i];
                uint256 value = values[i];
                bytes calldata payload = payloads[i];
                _execute(target, value, payload);
                emit CallExecuted(id, i, target, value, payload);
            }
            _afterCall(id);
        }
    }

    /**
     * @dev Execute an operation's call.
     */
    function _execute(
        address target,
        uint256 value,
        bytes calldata data
    ) internal virtual {
        (bool success, ) = target.call{value: value}(data);
        require(success, "ZivoeTimelockController: underlying transaction reverted");
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "ZivoeTimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "ZivoeTimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "ZivoeTimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCallKeeper(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReadyKeeper(id), "ZivoeTimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "ZivoeTimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCallKeeper(bytes32 id) private {
        require(isOperationReadyKeeper(id), "ZivoeTimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "ZivoeTimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../Utility/ZivoeSwapper.sol";

import "../../ZivoeLocker.sol";

import "../../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

interface IZivoeGlobals_OCC {
    /// @notice Returns the address of the ZivoeYDL contract.
    function YDL() external view returns (address);

    /// @notice Returns the net defaults in the system.
    /// @return amount The amount of net defaults in the system.
    function defaults() external view returns (uint256 amount);

    /// @notice Returns true if an address is whitelisted as a keeper.
    /// @return keeper Equals "true" if address is a keeper, "false" if not.
    function isKeeper(address) external view returns (bool keeper);

    /// @notice Handles WEI standardization of a given asset amount (i.e. 6 decimal precision => 18 decimal precision).
    /// @param amount The amount of a given "asset".
    /// @param asset The asset (ERC-20) from which to standardize the amount to WEI.
    /// @return standardizedAmount The above amount standardized to 18 decimals.
    function standardize(uint256 amount, address asset)
        external
        view
        returns (uint256 standardizedAmount);

    /// @notice Call when a default is resolved, decreases net defaults system-wide.
    /// @dev    The value "amount" should be standardized to WEI.
    /// @param  amount The default amount that has been resolved.
    function decreaseDefaults(uint256 amount) external;

    /// @notice Call when a default occurs, increases net defaults system-wide.
    /// @dev    The value "amount" should be standardized to WEI.
    /// @param  amount The default amount.
    function increaseDefaults(uint256 amount) external;
}

interface IZivoeYDL_OCC {
    /// @notice Returns the "stablecoin" that will be distributed via YDL.
    /// @return asset The address of the "stablecoin" that will be distributed via YDL.
    function distributedAsset() external view returns (address asset);
}

/// @notice  OCC stands for "On-Chain Credit".
///          A "balloon" loan is an interest-only loan, with principal repaid in full at the end.
///          An "amortized" loan is a principal and interest loan, with consistent payments until fully "Repaid".
///          This locker is responsible for handling accounting of loans.
///          This locker is responsible for handling payments and distribution of payments.
///          This locker is responsible for handling defaults and liquidations (if needed).
contract OCC_Modular is ZivoeLocker, ZivoeSwapper, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    /// @dev Tracks state of the loan, enabling or disabling certain actions (function calls).
    /// @param Initialized Loan request has been created, not funded (or passed expiry date).
    /// @param Active Loan has been funded, is currently receiving payments.
    /// @param Repaid Loan was funded, and has been fully repaid.
    /// @param Defaulted Default state, loan isn't initialized yet.
    /// @param Cancelled Loan request was created, then cancelled prior to funding.
    /// @param Resolved Loan was funded, then there was a default, then the full amount of principal was repaid.
    enum LoanState {
        Null,
        Initialized,
        Active,
        Repaid,
        Defaulted,
        Cancelled,
        Resolved
    }

    /// @dev Tracks payment schedule type of the loan.
    enum LoanSchedule {
        Balloon,
        Amortized
    }

    /// @dev Tracks the loan.
    struct Loan {
        address borrower; /// @dev The address that receives capital when the loan is funded.
        uint256 principalOwed; /// @dev The amount of principal still owed on the loan.
        uint256 APR; /// @dev The annualized percentage rate charged on the outstanding principal.
        uint256 APRLateFee; /// @dev The additional annualized percentage rate charged on the outstanding principal if payment is late.
        uint256 paymentDueBy; /// @dev The timestamp (in seconds) for when the next payment is due.
        uint256 paymentsRemaining; /// @dev The number of payments remaining until the loan is "Repaid".
        uint256 term; /// @dev The number of paymentIntervals that will occur, i.e. 10, 52, 200 in relation to "paymentInterval".
        uint256 paymentInterval; /// @dev The interval of time between payments (in seconds).
        uint256 requestExpiry; /// @dev The block.timestamp at which the request for this loan expires (hardcoded 2 weeks).
        uint256 gracePeriod; /// @dev The amount of time (in seconds) a borrower has to makePayment() before loan could default.
        int8 paymentSchedule; /// @dev The payment schedule of the loan (0 = "Balloon" or 1 = "Amortized").
        LoanState state; /// @dev The state of the loan.
    }

    address public immutable stablecoin; /// @dev The stablecoin for this OCC contract.
    address public immutable GBL; /// @dev The ZivoeGlobals contract.
    address public underwriter; /// @dev The entity that is allowed to underwrite (a.k.a. issue) loans.

    uint256 public counterID; /// @dev Tracks the IDs, incrementing overtime for the "loans" mapping.

    uint256 public amountForConversion; /// @dev The amount of stablecoin in this contract convertible and forwardable to YDL.

    mapping(uint256 => Loan) public loans; /// @dev Mapping of loans.

    uint256 private constant BIPS = 10000;

    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the OCC_Modular.sol contract.
    /// @param DAO The administrator of this contract (intended to be ZivoeDAO).
    /// @param _stablecoin The stablecoin for this OCC contract.
    /// @param _GBL The yield distribution locker that collects and distributes capital for this OCC locker.
    /// @param _underwriter The entity that is allowed to call fundLoan() and markRepaid().
    constructor(
        address DAO,
        address _stablecoin,
        address _GBL,
        address _underwriter
    ) {
        transferOwnershipAndLock(DAO);
        stablecoin = _stablecoin;
        GBL = _GBL;
        underwriter = _underwriter;
    }

    // ------------
    //    Events
    // ------------

    /// @notice Emitted during cancelRequest().
    /// @param  id Identifier for the loan request cancelled.
    event RequestCancelled(uint256 indexed id);

    /// @notice Emitted during requestLoan().
    /// @param  borrower        The address borrowing (that will receive the loan).
    /// @param  requestedBy     The address that created the loan request (usually same as borrower).
    /// @param  id              Identifier for the loan request created.
    /// @param  borrowAmount    The amount to borrow (in other words, initial principal).
    /// @param  APR             The annualized percentage rate charged on the outstanding principal.
    /// @param  APRLateFee      The annualized percentage rate charged on the outstanding principal (in addition to APR) for late payments.
    /// @param  term            The term or "duration" of the loan (this is the number of paymentIntervals that will occur, i.e. 10 monthly, 52 weekly).
    /// @param  paymentInterval The interval of time between payments (in seconds).
    /// @param  requestExpiry   The block.timestamp at which the request for this loan expires (hardcoded 2 weeks).
    /// @param  gracePeriod     The amount of time (in seconds) a borrower has to makePayment() before loan could default.
    /// @param  paymentSchedule The payment schedule type ("Balloon" or "Amortization").
    event RequestCreated(
        address indexed borrower,
        address requestedBy,
        uint256 indexed id,
        uint256 borrowAmount,
        uint256 APR,
        uint256 APRLateFee,
        uint256 term,
        uint256 paymentInterval,
        uint256 requestExpiry,
        uint256 gracePeriod,
        int8 indexed paymentSchedule
    );

    /// @notice Emitted during fundLoan().
    /// @param id Identifier for the loan funded.
    /// @param principal The amount of stablecoin funded.
    /// @param paymentDueBy Timestamp (unix seconds) by which next payment is due.
    event RequestFunded(
        uint256 indexed id,
        uint256 principal,
        address indexed borrower,
        uint256 paymentDueBy
    );

    /// @notice Emitted during makePayment() and processPayment().
    /// @param id Identifier for the loan on which payment is made.
    /// @param payee The address which made payment on the loan.
    /// @param amount The total amount of the payment.
    /// @param principal The principal portion of "amount" paid.
    /// @param interest The interest portion of "amount" paid.
    /// @param lateFee The lateFee portion of "amount" paid.
    /// @param nextPaymentDue The timestamp by which next payment is due.
    event PaymentMade(
        uint256 indexed id,
        address indexed payee,
        uint256 amount,
        uint256 principal,
        uint256 interest,
        uint256 lateFee,
        uint256 nextPaymentDue
    );

    /// @notice Emitted during markDefault().
    /// @param id Identifier for the loan which is now "defaulted".
    /// @param principalDefaulted The amount defaulted on.
    /// @param priorNetDefaults The prior amount of net (global) defaults.
    /// @param currentNetDefaults The new amount of net (global) defaults.
    event DefaultMarked(
        uint256 indexed id,
        uint256 principalDefaulted,
        uint256 priorNetDefaults,
        uint256 currentNetDefaults
    );

    /// @notice Emitted during markRepaid().
    /// @param id Identifier for loan which is now "repaid".
    event RepaidMarked(uint256 indexed id);

    /// @notice Emitted during callLoan().
    /// @param id Identifier for the loan which is called.
    /// @param amount The total amount of the payment.
    /// @param interest The interest portion of "amount" paid.
    /// @param principal The principal portion of "amount" paid.
    /// @param lateFee The lateFee portion of "amount" paid.
    event LoanCalled(
        uint256 indexed id,
        uint256 amount,
        uint256 principal,
        uint256 interest,
        uint256 lateFee
    );

    /// @notice Emitted during resolveDefault().
    /// @param id The identifier for the loan in default that is resolved (or partially).
    /// @param amount The amount of principal paid back.
    /// @param payee The address responsible for resolving the default.
    /// @param resolved Denotes if the loan is fully resolved (false if partial).
    event DefaultResolved(
        uint256 indexed id,
        uint256 amount,
        address indexed payee,
        bool resolved
    );

    /// @notice Emitted during supplyInterest().
    /// @param id The identifier for the loan that is supplied additional interest.
    /// @param amount The amount of interest supplied.
    /// @param payee The address responsible for supplying additional interest.
    event InterestSupplied(
        uint256 indexed id,
        uint256 amount,
        address indexed payee
    );

    /// @notice Emitted during forwardInterestKeeper().
    /// @param toAsset The asset converted to (dependent upon YDL.distributedAsset()).
    /// @param amountForConversion The amount of "stablecoin" available for conversion.
    /// @param amountConverted The amoount of "toAsset" received while converting interest.
    event InterestConverted(
        address indexed toAsset,
        uint256 amountForConversion,
        uint256 amountConverted
    );

    // ---------------
    //    Modifiers
    // ---------------

    /// @notice This modifier ensures that the caller is the entity that is allowed to issue loans.
    modifier isUnderwriter() {
        require(
            _msgSender() == underwriter,
            "OCC_Modular::isUnderwriter() _msgSender() != underwriter"
        );
        _;
    }

    // ---------------
    //    Functions
    // ---------------

    /// @notice Permission for owner to call pushToLocker().
    function canPush() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLocker().
    function canPull() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pushToLockerMulti().
    function canPushMulti() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLockerMulti().
    function canPullMulti() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pushToLockerPartial().
    function canPullPartial() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLockerMultiPartial().
    function canPullMultiPartial() public pure override returns (bool) {
        return true;
    }

    /// @notice Migrates entire ERC20 balance from locker to owner().
    /// @param  asset The asset to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLocker(address asset, bytes calldata data)
        external
        override
        onlyOwner
        nonReentrant
    {
        IERC20(asset).safeTransfer(
            owner(),
            IERC20(asset).balanceOf(address(this))
        );
        if (asset == stablecoin) {
            amountForConversion = 0;
        }
    }

    /// @notice Migrates specific amount of ERC20 from locker to owner().
    /// @param  asset The asset to migrate.
    /// @param  amount The amount of "asset" to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLockerPartial(
        address asset,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner nonReentrant {
        IERC20(asset).safeTransfer(owner(), amount);
        if (IERC20(stablecoin).balanceOf(address(this)) < amountForConversion) {
            amountForConversion = IERC20(stablecoin).balanceOf(address(this));
        }
    }

    /// @notice Returns information for amount owed on next payment of a particular loan.
    /// @param  id The ID of the loan.
    /// @return principal The amount of principal owed.
    /// @return interest The amount of interest owed.
    /// @return lateFee The amount of late fees owed.
    /// @return total Full amount owed, combining principal plus interested.
    function amountOwed(uint256 id)
        public
        view
        returns (
            uint256 principal,
            uint256 interest,
            uint256 lateFee,
            uint256 total
        )
    {
        // 0 == Balloon.
        if (loans[id].paymentSchedule == 0) {
            if (loans[id].paymentsRemaining == 1) {
                principal = loans[id].principalOwed;
            }
            interest =
                (loans[id].principalOwed *
                    loans[id].paymentInterval *
                    loans[id].APR) /
                (86400 * 365 * BIPS);
            // Add late fee if past paymentDueBy timestamp.
            if (
                block.timestamp > loans[id].paymentDueBy &&
                loans[id].state == LoanState.Active
            ) {
                lateFee =
                    (loans[id].principalOwed *
                        (block.timestamp - loans[id].paymentDueBy) *
                        (loans[id].APR + loans[id].APRLateFee)) /
                    (86400 * 365 * BIPS);
            }
            total = principal + interest + lateFee;
        }
        // 1 == Amortization (only two options, use else here).
        else {
            interest =
                (loans[id].principalOwed *
                    loans[id].paymentInterval *
                    loans[id].APR) /
                (86400 * 365 * BIPS);
            // Add late fee if past paymentDueBy timestamp.
            if (
                block.timestamp > loans[id].paymentDueBy &&
                loans[id].state == LoanState.Active
            ) {
                lateFee =
                    (loans[id].principalOwed *
                        (block.timestamp - loans[id].paymentDueBy) *
                        (loans[id].APR + loans[id].APRLateFee)) /
                    (86400 * 365 * BIPS);
            }
            principal = loans[id].principalOwed / loans[id].paymentsRemaining;
            total = principal + interest + lateFee;
        }
    }

    /// @notice Returns information for a given loan.
    /// @dev    Refer to documentation on Loan struct for return param information.
    /// @param  id The ID of the loan.
    /// @return borrower The borrower of the loan.
    /// @return paymentSchedule The structure of the payment schedule.
    /// @return details The remaining details of the loan:
    ///                  details[0] = principalOwed
    ///                  details[1] = APR
    ///                  details[2] = APRLateFee
    ///                  details[3] = paymentDueBy
    ///                  details[4] = paymentsRemaining
    ///                  details[5] = term
    ///                  details[6] = paymentInterval
    ///                  details[7] = requestExpiry
    ///                  details[8] = gracePeriod
    ///                  details[9] = loanState
    function loanInfo(uint256 id)
        external
        view
        returns (
            address borrower,
            int8 paymentSchedule,
            uint256[10] memory details
        )
    {
        borrower = loans[id].borrower;
        paymentSchedule = loans[id].paymentSchedule;
        details[0] = loans[id].principalOwed;
        details[1] = loans[id].APR;
        details[2] = loans[id].APRLateFee;
        details[3] = loans[id].paymentDueBy;
        details[4] = loans[id].paymentsRemaining;
        details[5] = loans[id].term;
        details[6] = loans[id].paymentInterval;
        details[7] = loans[id].requestExpiry;
        details[8] = loans[id].gracePeriod;
        details[9] = uint256(loans[id].state);
    }

    /// @notice Cancels a loan request.
    /// @param id The ID of the loan.
    function cancelRequest(uint256 id) external {
        require(
            _msgSender() == loans[id].borrower,
            "OCC_Modular::cancelRequest() _msgSender() != loans[id].borrower"
        );
        require(
            loans[id].state == LoanState.Initialized,
            "OCC_Modular::cancelRequest() loans[id].state != LoanState.Initialized"
        );

        emit RequestCancelled(id);
        loans[id].state = LoanState.Cancelled;
    }

    /// @notice                 Requests a loan.
    /// @param  borrower        The address to borrow (that receives the loan).
    /// @param  borrowAmount    The amount to borrow (in other words, initial principal).
    /// @param  APR             The annualized percentage rate charged on the outstanding principal.
    /// @param  APRLateFee      The annualized percentage rate charged on the outstanding principal (in addition to APR) for late payments.
    /// @param  term            The term or "duration" of the loan (this is the number of paymentIntervals that will occur, i.e. 10, 52, 200).
    /// @param  paymentInterval The interval of time between payments (in seconds).
    /// @param  gracePeriod     The amount of time (in seconds) the borrower has to makePayment() before loan could default.
    /// @param  paymentSchedule The payment schedule type ("Balloon" or "Amortization").
    function requestLoan(
        address borrower,
        uint256 borrowAmount,
        uint256 APR,
        uint256 APRLateFee,
        uint256 term,
        uint256 paymentInterval,
        uint256 gracePeriod,
        int8 paymentSchedule
    ) external {
        require(APR <= 3600, "OCC_Modular::requestLoan() APR > 3600");
        require(
            APRLateFee <= 3600,
            "OCC_Modular::requestLoan() APRLateFee > 3600"
        );
        require(term > 0, "OCC_Modular::requestLoan() term == 0");
        require(
            paymentInterval == 86400 * 7.5 ||
                paymentInterval == 86400 * 15 ||
                paymentInterval == 86400 * 30 ||
                paymentInterval == 86400 * 90 ||
                paymentInterval == 86400 * 360,
            "OCC_Modular::requestLoan() invalid paymentInterval value, try: 86400 * (7.5 || 15 || 30 || 90 || 360)"
        );
        require(
            paymentSchedule == 0 || paymentSchedule == 1,
            "OCC_Modular::requestLoan() paymentSchedule != 0 && paymentSchedule != 1"
        );

        emit RequestCreated(
            borrower,
            _msgSender(),
            counterID,
            borrowAmount,
            APR,
            APRLateFee,
            term,
            paymentInterval,
            block.timestamp + 14 days,
            gracePeriod,
            paymentSchedule
        );

        loans[counterID] = Loan(
            borrower,
            borrowAmount,
            APR,
            APRLateFee,
            0,
            term,
            term,
            paymentInterval,
            block.timestamp + 14 days,
            gracePeriod,
            paymentSchedule,
            LoanState.Initialized
        );

        counterID += 1;
    }

    /// @notice Funds and initiates a loan.
    /// @param  id The ID of the loan.
    function fundLoan(uint256 id) external isUnderwriter nonReentrant {
        require(
            loans[id].state == LoanState.Initialized,
            "OCC_Modular::fundLoan() loans[id].state != LoanState.Initialized"
        );
        require(
            block.timestamp < loans[id].requestExpiry,
            "OCC_Modular::fundLoan() block.timestamp >= loans[id].requestExpiry"
        );

        emit RequestFunded(
            id,
            loans[id].principalOwed,
            loans[id].borrower,
            block.timestamp + loans[id].paymentInterval
        );

        loans[id].state = LoanState.Active;
        loans[id].paymentDueBy = block.timestamp + loans[id].paymentInterval;
        IERC20(stablecoin).safeTransfer(
            loans[id].borrower,
            loans[id].principalOwed
        );

        if (IERC20(stablecoin).balanceOf(address(this)) < amountForConversion) {
            amountForConversion = IERC20(stablecoin).balanceOf(address(this));
        }
    }

    /// @notice Make a payment on a loan.
    /// @dev    Anyone is allowed to make a payment on someone's loan.
    /// @param  id The ID of the loan.
    function makePayment(uint256 id) external nonReentrant {
        require(
            loans[id].state == LoanState.Active,
            "OCC_Modular::makePayment() loans[id].state != LoanState.Active"
        );

        (
            uint256 principalOwed,
            uint256 interestOwed,
            uint256 lateFee,

        ) = amountOwed(id);

        emit PaymentMade(
            id,
            _msgSender(),
            principalOwed + interestOwed + lateFee,
            principalOwed,
            interestOwed,
            lateFee,
            loans[id].paymentDueBy + loans[id].paymentInterval
        );

        // Transfer interest + lateFee to YDL if in same format, otherwise keep here for 1INCH forwarding.
        if (
            stablecoin ==
            IZivoeYDL_OCC(IZivoeGlobals_OCC(GBL).YDL()).distributedAsset()
        ) {
            IERC20(stablecoin).safeTransferFrom(
                _msgSender(),
                IZivoeGlobals_OCC(GBL).YDL(),
                interestOwed + lateFee
            );
        } else {
            IERC20(stablecoin).safeTransferFrom(
                _msgSender(),
                address(this),
                interestOwed + lateFee
            );
            amountForConversion += interestOwed + lateFee;
        }

        IERC20(stablecoin).safeTransferFrom(
            _msgSender(),
            owner(),
            principalOwed
        );

        if (loans[id].paymentsRemaining == 1) {
            loans[id].state = LoanState.Repaid;
            loans[id].paymentDueBy = 0;
        } else {
            loans[id].paymentDueBy += loans[id].paymentInterval;
        }

        loans[id].principalOwed -= principalOwed;
        loans[id].paymentsRemaining -= 1;
    }

    /// @notice Process a payment for a loan, on behalf of another borrower.
    /// @dev    Anyone is allowed to process a payment, it will take from "borrower".
    /// @dev    Only allowed to call this if block.timestamp > paymentDueBy.
    /// @param  id The ID of the loan.
    function processPayment(uint256 id) external nonReentrant {
        require(
            loans[id].state == LoanState.Active,
            "OCC_Modular::processPayment() loans[id].state != LoanState.Active"
        );
        require(
            block.timestamp > loans[id].paymentDueBy - 3 days,
            "OCC_Modular::processPayment() block.timestamp <= loans[id].paymentDueBy - 3 days"
        );

        (
            uint256 principalOwed,
            uint256 interestOwed,
            uint256 lateFee,

        ) = amountOwed(id);

        emit PaymentMade(
            id,
            loans[id].borrower,
            principalOwed + interestOwed + lateFee,
            principalOwed,
            interestOwed,
            lateFee,
            loans[id].paymentDueBy + loans[id].paymentInterval
        );

        // Transfer interest to YDL if in same format, otherwise keep here for 1INCH forwarding.
        if (
            stablecoin ==
            IZivoeYDL_OCC(IZivoeGlobals_OCC(GBL).YDL()).distributedAsset()
        ) {
            IERC20(stablecoin).safeTransferFrom(
                loans[id].borrower,
                IZivoeGlobals_OCC(GBL).YDL(),
                interestOwed + lateFee
            );
        } else {
            IERC20(stablecoin).safeTransferFrom(
                loans[id].borrower,
                address(this),
                interestOwed + lateFee
            );
            amountForConversion += interestOwed + lateFee;
        }

        IERC20(stablecoin).safeTransferFrom(
            loans[id].borrower,
            owner(),
            principalOwed
        );

        if (loans[id].paymentsRemaining == 1) {
            loans[id].state = LoanState.Repaid;
            loans[id].paymentDueBy = 0;
        } else {
            loans[id].paymentDueBy += loans[id].paymentInterval;
        }

        loans[id].principalOwed -= principalOwed;
        loans[id].paymentsRemaining -= 1;
    }

    /// @notice Pays off the loan in full, plus additional interest for paymentInterval.
    /// @dev    Only the "borrower" of the loan may elect this option.
    /// @param  id The loan to pay off early.
    function callLoan(uint256 id) external nonReentrant {
        require(
            _msgSender() == loans[id].borrower,
            "OCC_Modular::callLoan() _msgSender() != loans[id].borrower"
        );
        require(
            loans[id].state == LoanState.Active,
            "OCC_Modular::callLoan() loans[id].state != LoanState.Active"
        );

        uint256 principalOwed = loans[id].principalOwed;
        (, uint256 interestOwed, uint256 lateFee, ) = amountOwed(id);

        emit LoanCalled(
            id,
            principalOwed + interestOwed + lateFee,
            principalOwed,
            interestOwed,
            lateFee
        );

        // Transfer interest to YDL if in same format, otherwise keep here for 1INCH forwarding.
        if (
            stablecoin ==
            IZivoeYDL_OCC(IZivoeGlobals_OCC(GBL).YDL()).distributedAsset()
        ) {
            IERC20(stablecoin).safeTransferFrom(
                _msgSender(),
                IZivoeGlobals_OCC(GBL).YDL(),
                interestOwed + lateFee
            );
        } else {
            IERC20(stablecoin).safeTransferFrom(
                _msgSender(),
                address(this),
                interestOwed + lateFee
            );
            amountForConversion += interestOwed + lateFee;
        }

        IERC20(stablecoin).safeTransferFrom(
            _msgSender(),
            owner(),
            principalOwed
        );

        loans[id].principalOwed = 0;
        loans[id].paymentDueBy = 0;
        loans[id].paymentsRemaining = 0;
        loans[id].state = LoanState.Repaid;
    }

    /// @notice Mark a loan insolvent if a payment hasn't been made beyond the corresponding grace period.
    /// @param  id The ID of the loan.
    function markDefault(uint256 id) external {
        require(
            loans[id].state == LoanState.Active,
            "OCC_Modular::markDefault() loans[id].state != LoanState.Active"
        );
        require(
            loans[id].paymentDueBy + loans[id].gracePeriod < block.timestamp,
            "OCC_Modular::markDefault() loans[id].paymentDueBy + loans[id].gracePeriod >= block.timestamp"
        );

        emit DefaultMarked(
            id,
            loans[id].principalOwed,
            IZivoeGlobals_OCC(GBL).defaults(),
            IZivoeGlobals_OCC(GBL).defaults() +
                IZivoeGlobals_OCC(GBL).standardize(
                    loans[id].principalOwed,
                    stablecoin
                )
        );
        loans[id].state = LoanState.Defaulted;
        IZivoeGlobals_OCC(GBL).increaseDefaults(
            IZivoeGlobals_OCC(GBL).standardize(
                loans[id].principalOwed,
                stablecoin
            )
        );
    }

    /// @notice Underwriter specifies a loan has been repaid fully via interest deposits in terms of off-chain debt.
    /// @param  id The ID of the loan.
    function markRepaid(uint256 id) external isUnderwriter {
        require(
            loans[id].state == LoanState.Resolved,
            "OCC_Modular::markRepaid() loans[id].state != LoanState.Resolved"
        );

        emit RepaidMarked(id);
        loans[id].state = LoanState.Repaid;
    }

    /// @notice Make a full (or partial) payment to resolve a insolvent loan.
    /// @param  id The ID of the loan.
    /// @param  amount The amount of principal to pay down.
    function resolveDefault(uint256 id, uint256 amount) external {
        require(
            loans[id].state == LoanState.Defaulted,
            "OCC_Modular::resolveDefaut() loans[id].state != LoanState.Defaulted"
        );

        uint256 paymentAmount;

        if (amount >= loans[id].principalOwed) {
            paymentAmount = loans[id].principalOwed;
            loans[id].principalOwed = 0;
            loans[id].state = LoanState.Resolved;
        } else {
            paymentAmount = amount;
            loans[id].principalOwed -= paymentAmount;
        }

        emit DefaultResolved(
            id,
            paymentAmount,
            _msgSender(),
            loans[id].state == LoanState.Resolved
        );

        IERC20(stablecoin).safeTransferFrom(
            _msgSender(),
            owner(),
            paymentAmount
        );
        IZivoeGlobals_OCC(GBL).decreaseDefaults(
            IZivoeGlobals_OCC(GBL).standardize(paymentAmount, stablecoin)
        );
    }

    /// @notice Supply interest to a repaid loan (for arbitrary interest repayment).
    /// @param  id The ID of the loan.
    /// @param  amount The amount of interest to supply.
    function supplyInterest(uint256 id, uint256 amount) external nonReentrant {
        require(
            loans[id].state == LoanState.Resolved,
            "OCC_Modular::supplyInterest() loans[id].state != LoanState.Resolved"
        );

        emit InterestSupplied(id, amount, _msgSender());
        // Transfer interest to YDL if in same format, otherwise keep here for 1INCH forwarding.
        if (
            stablecoin ==
            IZivoeYDL_OCC(IZivoeGlobals_OCC(GBL).YDL()).distributedAsset()
        ) {
            IERC20(stablecoin).safeTransferFrom(
                _msgSender(),
                IZivoeGlobals_OCC(GBL).YDL(),
                amount
            );
        } else {
            IERC20(stablecoin).safeTransferFrom(
                _msgSender(),
                address(this),
                amount
            );
            amountForConversion += amount;
        }
    }

    /// @notice This function converts and forwards available "amountForConversion" to YDL.distributeAsset().
    /// @param data The data retrieved from 1inch API in order to execute the swap.
    function forwardInterestKeeper(bytes calldata data) external nonReentrant {
        require(
            IZivoeGlobals_OCC(GBL).isKeeper(_msgSender()),
            "OCC_Modular::forwardInterestKeeper() !IZivoeGlobals_OCC(GBL).isKeeper(_msgSender())"
        );
        address _toAsset = IZivoeYDL_OCC(IZivoeGlobals_OCC(GBL).YDL())
            .distributedAsset();
        require(
            _toAsset != stablecoin,
            "OCC_Modular::forwardInterestKeeper() _toAsset == stablecoin"
        );

        // Swap available "amountForConversion" from stablecoin to YDL.distributedAsset().
        convertAsset(stablecoin, _toAsset, amountForConversion, data);

        emit InterestConverted(
            _toAsset,
            amountForConversion,
            IERC20(_toAsset).balanceOf(address(this))
        );

        // Transfer all _toAsset received to the YDL, then reduce amountForConversion to 0.
        IERC20(_toAsset).safeTransfer(
            IZivoeGlobals_OCC(GBL).YDL(),
            IERC20(_toAsset).balanceOf(address(this))
        );
        amountForConversion = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../ZivoeLocker.sol";

import "../../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

interface IZivoeGlobals_OCE_ZVE {
    /// @notice Returns the address of the ZivoeRewards.sol ($ZVE) contract.
    function stZVE() external view returns (address);

    /// @notice Returns the address of the ZivoeRewards.sol ($zSTT) contract.
    function stSTT() external view returns (address);

    /// @notice Returns the address of the ZivoeRewards.sol ($zJTT) contract.
    function stJTT() external view returns (address);

    /// @notice Returns the address of the Timelock contract.
    function TLC() external view returns (address);

    /// @notice Returns the address of the ZivoeYDL.sol contract.
    function YDL() external view returns (address);

    /// @notice Returns the address of the ZivoeToken.sol contract.
    function ZVE() external view returns (address ZVE);

    /// @notice Returns the net defaults in the system.
    /// @return amount The amount of net defaults in the system.
    function defaults() external view returns (uint256 amount);

    /// @notice Returns true if an address is whitelisted as a keeper.
    /// @return keeper Equals "true" if address is a keeper, "false" if not.
    function isKeeper(address) external view returns (bool keeper);

    /// @notice Handles WEI standardization of a given asset amount (i.e. 6 decimal precision => 18 decimal precision).
    /// @param amount The amount of a given "asset".
    /// @param asset The asset (ERC-20) from which to standardize the amount to WEI.
    /// @return standardizedAmount The above amount standardized to 18 decimals.
    function standardize(uint256 amount, address asset) external view returns (uint256 standardizedAmount);

    /// @notice Call when a default is resolved, decreases net defaults system-wide.
    /// @dev    The value "amount" should be standardized to WEI.
    /// @param  amount The default amount that has been resolved.
    function decreaseDefaults(uint256 amount) external;

    /// @notice Call when a default occurs, increases net defaults system-wide.
    /// @dev    The value "amount" should be standardized to WEI.
    /// @param  amount The default amount.
    function increaseDefaults(uint256 amount) external;
}

interface IZivoeRewards_OCE_ZVE {
    /// @notice Deposits a reward to this contract for distribution.
    /// @param _rewardsToken The asset that's being distributed.
    /// @param reward The amount of the _rewardsToken to deposit.
    function depositReward(address _rewardsToken, uint256 reward) external;
}

/// @notice This contract facilitates an exponential decay emissions schedule for $ZVE.
///         This contract has the following responsibilities:
///           - Handles accounting (with governable variables) to support emissions schedule.
///           - Forwards $ZVE to all ZivoeRewards contracts at will (stZVE, stSTT, stJTT).
contract OCE_ZVE is ZivoeLocker, ReentrancyGuard {
    
    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    address public immutable GBL;           /// @dev The ZivoeGlobals contract.

    uint256 public lastDistribution;        /// @dev The block.timestamp value of last distribution.

    uint256 public exponentialDecayPerSecond = RAY * 99999998 / 100000000;    /// @dev The rate of decay per second.

    /// @dev Determines distribution between rewards contract, in BIPS.
    /// @dev The sum of distributionRatioBIPS[0], distributionRatioBIPS[1], and distributionRatioBIPS[2] must equal BIPS.
    ///      distributionRatioBIPS[0] => stZVE
    ///      distributionRatioBIPS[1] => stSTT
    ///      distributionRatioBIPS[2] => stJTT
    uint256[3] public distributionRatioBIPS;

    uint256 private constant BIPS = 10000;
    uint256 private constant RAY = 10 ** 27;



    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the OCE_ZVE.sol contract.
    /// @param DAO The administrator of this contract (intended to be ZivoeDAO).
    /// @param _GBL The ZivoeGlobals contract.
    constructor(
        address DAO,
        address _GBL
    ) {
        transferOwnership(DAO);
        GBL = _GBL;
        lastDistribution = block.timestamp;
    }

    // ------------
    //    Events
    // ------------

    /// @notice Emitted during updateDistributionRatioBIPS().
    /// @param  oldRatios The old distribution ratios.
    /// @param  newRatios The new distribution ratios.
    event UpdatedDistributionRatioBIPS(uint256[3] oldRatios, uint256[3] newRatios);

    /// @notice Emitted during forwardEmissions().
    /// @param  stZVE The amount of $ZVE emitted to the $ZVE rewards contract.
    /// @param  stJTT The amount of $ZVE emitted to the $zJTT rewards contract.
    /// @param  stSTT The amount of $ZVE emitted to the $zSTT rewards contract.
    event EmissionsForwarded(uint256 stZVE, uint256 stJTT, uint256 stSTT);

    /// @notice Emitted during setExponentialDecayPerSecond().
    /// @param  oldValue The old value of exponentialDecayPerSecond.
    /// @param  newValue The new value of exponentialDecayPerSecond.
    event UpdatedExponentialDecayPerSecond(uint256 oldValue, uint256 newValue);



    // ---------------
    //    Functions
    // ---------------

    /// @notice Permission for owner to call pushToLocker().
    function canPush() public override pure returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLocker().
    function canPull() public override pure returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLockerPartial().
    function canPullPartial() public override pure returns (bool) {
        return true;
    }

    /// @notice Allocates ZVE from the DAO to this locker for emissions, automatically forwards 50% of ZVE to emissions schedule.
    /// @dev    Only callable by the DAO.
    /// @param  asset The asset to push to this locker (in this case $ZVE).
    /// @param  amount The amount of $ZVE to push to this locker.
    /// @param  data Accompanying transaction data.
    function pushToLocker(address asset, uint256 amount, bytes calldata data) external override onlyOwner {
        require(asset == IZivoeGlobals_OCE_ZVE(GBL).ZVE(), "OCE_ZVE::pushToLocker() asset != IZivoeGlobals_OCE_ZVE(GBL).ZVE()");
        
        IERC20(asset).safeTransferFrom(owner(), address(this), amount);
    }
    
    /// @notice Updates the distribution between rewards contract, in BIPS.
    /// @dev    The sum of distributionRatioBIPS[0], distributionRatioBIPS[1], and distributionRatioBIPS[2] must equal BIPS.
    /// @param  _distributionRatioBIPS The updated values for the state variable distributionRatioBIPS.
    function updateDistributionRatioBIPS(uint256[3] calldata _distributionRatioBIPS) external {
        require(_msgSender() == IZivoeGlobals_OCE_ZVE(GBL).TLC(), "OCE_ZVE::updateDistributionRatioBIPS() _msgSender() != IZivoeGlobals_OCE_ZVE(GBL).TLC()");
        require(
            _distributionRatioBIPS[0] + _distributionRatioBIPS[1] + _distributionRatioBIPS[2] == BIPS,
            "OCE_ZVE::updateDistributionRatioBIPS() _distributionRatioBIPS[0] + _distributionRatioBIPS[1] + _distributionRatioBIPS[2] != BIPS"
        );

        emit UpdatedDistributionRatioBIPS(distributionRatioBIPS, _distributionRatioBIPS);
        distributionRatioBIPS[0] = _distributionRatioBIPS[0];
        distributionRatioBIPS[1] = _distributionRatioBIPS[1];
        distributionRatioBIPS[2] = _distributionRatioBIPS[2];
    }

    /// @notice Forwards $ZVE available for distribution.
    function forwardEmissions() external nonReentrant {
        _forwardEmissions(
            IERC20(IZivoeGlobals_OCE_ZVE(GBL).ZVE()).balanceOf(address(this)) - 
            decay(IERC20(IZivoeGlobals_OCE_ZVE(GBL).ZVE()).balanceOf(address(this)), block.timestamp - lastDistribution)
        );
        lastDistribution = block.timestamp;
    }

    /// @notice This handles the accounting for forwarding ZVE to lockers privately.
    /// @param amount The amount of $ZVE to distribute.
    function _forwardEmissions(uint256 amount) private {
        emit EmissionsForwarded(
            amount * distributionRatioBIPS[0] / BIPS,
            amount * distributionRatioBIPS[1] / BIPS,
            amount * distributionRatioBIPS[2] / BIPS
        );
        IERC20(IZivoeGlobals_OCE_ZVE(GBL).ZVE()).safeApprove(IZivoeGlobals_OCE_ZVE(GBL).stZVE(), amount * distributionRatioBIPS[0] / BIPS);
        IERC20(IZivoeGlobals_OCE_ZVE(GBL).ZVE()).safeApprove(IZivoeGlobals_OCE_ZVE(GBL).stSTT(), amount * distributionRatioBIPS[1] / BIPS);
        IERC20(IZivoeGlobals_OCE_ZVE(GBL).ZVE()).safeApprove(IZivoeGlobals_OCE_ZVE(GBL).stJTT(), amount * distributionRatioBIPS[2] / BIPS);
        IZivoeRewards_OCE_ZVE(IZivoeGlobals_OCE_ZVE(GBL).stZVE()).depositReward(IZivoeGlobals_OCE_ZVE(GBL).ZVE(), amount * distributionRatioBIPS[0] / BIPS);
        IZivoeRewards_OCE_ZVE(IZivoeGlobals_OCE_ZVE(GBL).stSTT()).depositReward(IZivoeGlobals_OCE_ZVE(GBL).ZVE(), amount * distributionRatioBIPS[1] / BIPS);
        IZivoeRewards_OCE_ZVE(IZivoeGlobals_OCE_ZVE(GBL).stJTT()).depositReward(IZivoeGlobals_OCE_ZVE(GBL).ZVE(), amount * distributionRatioBIPS[2] / BIPS);
    }

    /// @notice Updates the exponentialDecayPerSecond variable with provided input.
    /// @dev    For 1.0000% decrease per second, _exponentialDecayPerSecond would be (1 - 0.01) * RAY.
    /// @dev    For 0.0001% decrease per second, _exponentialDecayPerSecond would be (1 - 0.000001) * RAY.
    /// @param _exponentialDecayPerSecond The updated value for exponentialDecayPerSecond state variable.
    function setExponentialDecayPerSecond(uint256 _exponentialDecayPerSecond) external {
        require(_msgSender() == IZivoeGlobals_OCE_ZVE(GBL).TLC(), "OCE_ZVE::setExponentialDecayPerSecond() _msgSender() != IZivoeGlobals_OCE_ZVE(GBL).TLC()");
        
        emit UpdatedExponentialDecayPerSecond(exponentialDecayPerSecond, _exponentialDecayPerSecond);
        exponentialDecayPerSecond = _exponentialDecayPerSecond; 
    }



    // ----------
    //    Math
    // ----------

    /// @notice Returns the amount remaining after a decay.
    /// @param top The amount decaying.
    /// @param dur The seconds of decay.
    function decay(uint256 top, uint256 dur) public view returns (uint256) {
        return rmul(top, rpow(exponentialDecayPerSecond, dur, RAY));
    }

    // rmul() and rpow() were ported from MakerDAO:
    // https://github.com/makerdao/dss/blob/master/src/abaci.sol

    /// @notice Multiplies two variables and returns value, truncated by RAY precision.
    /// @param x First value to multiply.
    /// @param y Second value to multiply.
    /// @return z Resulting value of x * y, truncated by RAY precision.
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        require(y == 0 || z / y == x, "OCE_ZVE::rmul() y != 0 && z / y != x");
        z = z / RAY;
    }
    
    /**
        @notice rpow(uint x, uint n, uint b), used for exponentiation in drip, is a fixed-point arithmetic function 
                that raises x to the power n. It is implemented in Solidity assembly as a repeated squaring algorithm. 
                x and the returned value are to be interpreted as fixed-point integers with scaling factor b. 
                For example, if b == 100, this specifies two decimal digits of precision and the normal decimal value 
                2.1 would be represented as 210; rpow(210, 2, 100) returns 441 (the two-decimal digit fixed-point 
                representation of 2.1^2 = 4.41). In the current implementation, 10^27 is passed for b, making x and 
                the rpow result both of type RAY in standard MCD fixed-point terminology. rpow's formal invariants 
                include "no overflow" as well as constraints on gas usage.
        @param  x The base value.
        @param  n The power to raise "x" by.
        @param  b The scaling factor, a.k.a. resulting precision of "z".
        @return z Resulting value of x^n, scaled by factor b.
    */
    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
        assembly {
            switch n case 0 { z := b }
            default {
                switch x case 0 { z := 0 }
                default {
                    switch mod(n, 2) case 0 { z := b } default { z := x }
                    let half := div(b, 2)  // For rounding.
                    for { n := div(n, 2) } n { n := div(n,2) } {
                        let xx := mul(x, x)
                        if shr(128, x) { revert(0,0) }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) { revert(0,0) }
                        x := div(xxRound, b)
                        if mod(n,2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) { revert(0,0) }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../ZivoeLocker.sol";

interface IZivoeGlobals_OCG_Defaults {
    function TLC() external view returns (address);
    function decreaseDefaults(uint256) external;
    function increaseDefaults(uint256) external;
}

/// @notice This contract is for testing default adjustments via ZivoeLocker.
contract OCG_Defaults is ZivoeLocker {
    
    
    // ---------------------
    //    State Variables
    // ---------------------

    address public GBL;  /// @dev The ZivoeGlobals contract.


    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the OCY_Generic.sol contract.
    /// @param DAO The administrator of this contract (intended to be ZivoeDAO).
    constructor(address DAO, address _GBL) {
        transferOwnership(DAO);
        GBL = _GBL;
    }



    // ---------------
    //    Modifiers
    // ---------------

    /// @notice This modifier ensures that the caller is the timelock contract.
    modifier onlyGovernance {
        require(_msgSender() == IZivoeGlobals_OCG_Defaults(GBL).TLC(),
        "OCG_Defaults::onlyGovernance() _msgSender!= IZivoeGlobals_OCG_Defaults(GBL).TLC()");
        _;
    }



    // ---------------
    //    Functions
    // ---------------

    /// @notice This function will decrease the net defaults in the ZivoeGlobals contract.
    /// @param amount The amount by which the defaults should be reduced.
    function decreaseDefaults(uint256 amount) public onlyGovernance {
        IZivoeGlobals_OCG_Defaults(GBL).decreaseDefaults(amount);
    }


    /// @notice This function will increase the net defaults in the ZivoeGlobals contract.
    /// @param amount The amount by which the defaults should be increased.
    function increaseDefaults(uint256 amount) public onlyGovernance {
        IZivoeGlobals_OCG_Defaults(GBL).increaseDefaults(amount);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../ZivoeLocker.sol";

/// @notice This contract is for testing generic ERC1155 ZivoeLocker functions (inherited non-overridden functions).
contract OCG_ERC1155 is ZivoeLocker {
    
    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the OCY_Generic.sol contract.
    /// @param DAO The administrator of this contract (intended to be ZivoeDAO).
    constructor(address DAO) {
        transferOwnership(DAO);
    }



    // ---------------
    //    Functions
    // ---------------

    /// @notice Permission for owner to call pushToLockerERC1155().
    function canPushERC1155() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLockerERC1155().
    function canPullERC1155() public pure override returns (bool) {
        return true;
    }


}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../ZivoeLocker.sol";

/// @notice This contract is for testing generic ERC20 ZivoeLocker functions (inherited non-overridden functions).
contract OCG_ERC20 is ZivoeLocker {
    
    // -----------------
    //    Constructor
    // -----------------
    
    /// @notice Initializes the OCY_Generic.sol contract.
    /// @param DAO The administrator of this contract (intended to be ZivoeDAO).
    constructor(address DAO) {
        transferOwnership(DAO);
    }



    // ---------------
    //    Functions
    // ---------------

    /// @notice Permission for owner to call pushToLocker().
    function canPush() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLocker().
    function canPull() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLockerPartial().
    function canPullPartial() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pushToLockerMulti().
    function canPushMulti() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLockerMulti().
    function canPullMulti() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLockerMultiPartial().
    function canPullMultiPartial() public pure override returns (bool) {
        return true;
    }


}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../ZivoeLocker.sol";

/// @notice This contract is for testing generic ERC721 ZivoeLocker functions (inherited non-overridden functions).
contract OCG_ERC721 is ZivoeLocker {
    
    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the OCY_Generic.sol contract.
    /// @param DAO The administrator of this contract (intended to be ZivoeDAO).
    constructor(address DAO) {
        transferOwnership(DAO);
    }



    // ---------------
    //    Functions
    // ---------------

    /// @notice Permission for owner to call pushToLockerERC721().
    function canPushERC721() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLockerERC721().
    function canPullERC721() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pushToLockerMultiERC721().
    function canPushMultiERC721() public pure override returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLockerMultiERC721().
    function canPullMultiERC721() public pure override returns (bool) {
        return true;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../ZivoeLocker.sol";

import { IZivoeGlobals, ICRVDeployer, ICRVMetaPool, ICRVPlainPoolFBP } from "../../misc/InterfacesAggregated.sol";

// NOTE: This contract is considered defunct, no intention to use CRV for $ZVE secondary market purposes.
// NOTE: This contract is maintained in the repository for future reference and implementation purposes.

contract OCL_ZVE_CRV_0 is ZivoeLocker {
    
    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    address public constant CRV_Deployer = 0xB9fC157394Af804a3578134A6585C0dc9cc990d4;  /// @dev CRV.FI deployer for meta-pools.
    address public constant FBP_BP = 0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2;        /// @dev FRAX BasePool (FRAX/USDC) for CRV Finance.
    address public constant FBP_TOKEN = 0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC;     /// @dev Frax BasePool LP token address.
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;          /// @dev The FRAX stablecoin.
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;          /// @dev The USDC stablecoin.

    address public ZVE_MP;          /// @dev To be determined upon pool deployment via constructor().
    address public immutable GBL;   /// @dev The ZivoeGlobals contract.

    uint256 public baseline;                /// @dev FRAX convertible, used for forwardYield() accounting.
    uint256 public nextYieldDistribution;   /// @dev Determines next available forwardYield() call.
    
    // -----------
    // Constructor
    // -----------

    /// @notice Initializes the OCL_ZVE_CRV_0.sol contract.
    /// @param DAO The administrator of this contract (intended to be ZivoeDAO).
    /// @param _GBL The ZivoeGlobals contract.
    constructor(
        address DAO,
        address _GBL
    ) {
        transferOwnership(DAO);
        GBL = _GBL;
        ZVE_MP = ICRVDeployer(CRV_Deployer).deploy_metapool(
            FBP_BP,                     /// The base-pool (FBP = FraxBasePool).
            "ZVE_MetaPool_FBP",         /// Name of meta-pool.
            "ZVE/FBP",                  /// Symbol of meta-pool.
            IZivoeGlobals(_GBL).ZVE(),  /// Coin paired with base-pool. ($ZVE).
            250,                        /// Amplifier.
            20000000                    /// 0.20% fee.
        );
    }

    // ---------
    // Functions
    // ---------

    function canPullPartial() public override pure returns (bool) {
        return true;
    }

    function canPushMulti() public override pure returns (bool) {
        return true;
    }

    function canPullMulti() public override pure returns (bool) {
        return true;
    }

    /// @dev    This pulls capital from the DAO, does any necessary pre-conversions, and adds liquidity into ZVE MetaPool.
    /// @param  data Accompanying transaction data.
    function pushToLockerMulti(address[] calldata assets, uint256[] calldata amounts, bytes[] calldata data) external override onlyOwner {
        require(
            (assets[0] == FRAX || assets[0] == USDC) && assets[1] == IZivoeGlobals(GBL).ZVE(),
            "OCL_ZVE_CRV_0::pushToLockerMulti() (assets[0] != FRAX && assets[0] == USDC) || assets[1] != IZivoeGlobals(GBL).ZVE()"
        );

        for (uint256 i = 0; i < 2; i++) {
            IERC20(assets[i]).safeTransferFrom(owner(), address(this), amounts[i]);
        }
        if (nextYieldDistribution == 0) {
            nextYieldDistribution = block.timestamp + 30 days;
        }
        uint256 preBaseline;
        if (baseline != 0) {
            (preBaseline,) = FRAXConvertible();
        }
        // FRAX || USDC, BasePool Deposit
        // FBP.coins(0) == FRAX
        // FBP.coins(1) == USDC
        if (assets[0] == FRAX) {
            IERC20(FRAX).safeApprove(FBP_BP, IERC20(FRAX).balanceOf(address(this)));
            uint256[2] memory deposits_bp;
            deposits_bp[0] = IERC20(FRAX).balanceOf(address(this));
            ICRVPlainPoolFBP(FBP_BP).add_liquidity(deposits_bp, 0);
        }
        else {
            IERC20(USDC).safeApprove(FBP_BP, IERC20(USDC).balanceOf(address(this)));
            uint256[2] memory deposits_bp;
            deposits_bp[1] = IERC20(USDC).balanceOf(address(this));
            ICRVPlainPoolFBP(FBP_BP).add_liquidity(deposits_bp, 0);
        }
        // FBP && ZVE, MetaPool Deposit
        // ZVE_MP.coins(0) == ZVE
        // ZVE_MP.coins(1) == FBP
        IERC20(FBP_TOKEN).safeApprove(ZVE_MP, IERC20(FBP_TOKEN).balanceOf(address(this)));
        IERC20(IZivoeGlobals(GBL).ZVE()).safeApprove(ZVE_MP, IERC20(IZivoeGlobals(GBL).ZVE()).balanceOf(address(this)));
        uint256[2] memory deposits_mp;
        deposits_mp[0] = IERC20(IZivoeGlobals(GBL).ZVE()).balanceOf(address(this));
        deposits_mp[1] = IERC20(FBP_TOKEN).balanceOf(address(this));
        ICRVMetaPool(ZVE_MP).add_liquidity(deposits_mp, 0);
        // Increase baseline.
        (uint256 postBaseline,) = FRAXConvertible();
        require(postBaseline > preBaseline, "OCL_ZVE_CRV_0::pushToLockerMulti() postBaseline < preBaseline");
        baseline = postBaseline - preBaseline;
    }

    /// @dev    This burns LP tokens from the ZVE MetaPool, and returns resulting coins back to the DAO.
    /// @param  assets The assets to return.
    /// @param  data Accompanying transaction data.
    function pullFromLockerMulti(address[] calldata assets, bytes[] calldata data) external override onlyOwner {
        require(
            assets[0] == USDC && assets[1] == FRAX && assets[2] == IZivoeGlobals(GBL).ZVE(),
            "OCL_ZVE_CRV_0::pullFromLockerMulti() assets[0] != USDC || assets[1] != FRAX || assets[2] != IZivoeGlobals(GBL).ZVE()"
        );

        uint256[2] memory tester;
        ICRVMetaPool(ZVE_MP).remove_liquidity(
            IERC20(ZVE_MP).balanceOf(address(this)), tester
        );
        ICRVPlainPoolFBP(FBP_BP).remove_liquidity(
            IERC20(FBP_TOKEN).balanceOf(address(this)), tester
        );
        IERC20(USDC).safeTransfer(owner(), IERC20(USDC).balanceOf(address(this)));
        IERC20(FRAX).safeTransfer(owner(), IERC20(FRAX).balanceOf(address(this)));
        IERC20(IZivoeGlobals(GBL).ZVE()).safeTransfer(owner(), IERC20(IZivoeGlobals(GBL).ZVE()).balanceOf(address(this)));
        baseline = 0;
    }

    /// @dev    This burns a partial amount of LP tokens from the ZVE MetaPool, and returns resulting coins back to the DAO.
    /// @param  asset The LP token to burn.
    /// @param  amount The amount of LP tokens to burn.
    /// @param  data Accompanying transaction data.
    function pullFromLockerPartial(address asset, uint256 amount, bytes calldata data) external override onlyOwner {
        require(asset == ZVE_MP, "OCL_ZVE_CRV_0::pullFromLockerPartial() assets != ZVE_MP");

        uint256[2] memory tester;
        ICRVMetaPool(ZVE_MP).remove_liquidity(
            amount, tester
        );
        ICRVPlainPoolFBP(FBP_BP).remove_liquidity(
            IERC20(FBP_TOKEN).balanceOf(address(this)), tester
        );
        IERC20(USDC).safeTransfer(owner(), IERC20(USDC).balanceOf(address(this)));
        IERC20(FRAX).safeTransfer(owner(), IERC20(FRAX).balanceOf(address(this)));
        IERC20(IZivoeGlobals(GBL).ZVE()).safeTransfer(owner(), IERC20(IZivoeGlobals(GBL).ZVE()).balanceOf(address(this)));
        baseline = 0;
    }

    /// @dev    This forwards yield to the YDL.
    function forwardYield() external {
        if (IZivoeGlobals(GBL).isKeeper(_msgSender())) {
            require(
                block.timestamp > nextYieldDistribution - 12 hours, 
                "OCL_ZVE_CRV_0::forwardYield() block.timestamp <= nextYieldDistribution - 12 hours"
            );
        }
        else {
            require(block.timestamp > nextYieldDistribution, "OCL_ZVE_CRV_0::forwardYield() block.timestamp <= nextYieldDistribution");
        }
        (uint256 amount, uint256 lp) = FRAXConvertible();
        require(amount > baseline, "OCL_ZVE_CRV_0::forwardYield() amount <= baseline");
        nextYieldDistribution = block.timestamp + 30 days;
        _forwardYield(amount, lp);
    }

    /// @dev Returns information on how much FRAX is convertible via current LP tokens.
    /// @return amount Current FRAX harvestable.
    /// @return lp Current ZVE_MP tokens.
    /// @notice The withdrawal mechanism is ZVE_MP => FBP => Frax.
    function FRAXConvertible() public view returns (uint256 amount, uint256 lp) {
        lp = IERC20(ZVE_MP).balanceOf(address(this));
        amount = ICRVPlainPoolFBP(FBP_BP).calc_withdraw_one_coin(
            ICRVMetaPool(ZVE_MP).calc_withdraw_one_coin(lp, int128(1)), int128(0)
        );
    }

    function _forwardYield(uint256 amount, uint256 lp) private {
        uint256 lpBurnable = (amount - baseline) * lp / amount / 2; 
        ICRVMetaPool(ZVE_MP).remove_liquidity_one_coin(lpBurnable, 1, 0);
        ICRVPlainPoolFBP(FBP_BP).remove_liquidity_one_coin(IERC20(FBP_TOKEN).balanceOf(address(this)), int128(0), 0);
        IERC20(FRAX).safeTransfer(IZivoeGlobals(GBL).YDL(), IERC20(FRAX).balanceOf(address(this)));
        (baseline,) = FRAXConvertible();
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../ZivoeLocker.sol";

import { IZivoeGlobals, ICRVDeployer, ICRVMetaPool, ICRVPlainPool3CRV } from "../../misc/InterfacesAggregated.sol";

// NOTE: This contract is considered defunct, no intention to use CRV for $ZVE secondary market purposes.
// NOTE: This contract is maintained in the repository for future reference and implementation purposes.

contract OCL_ZVE_CRV_1 is ZivoeLocker {
    
    using SafeERC20 for IERC20;
    
    // ---------------------
    //    State Variables
    // ---------------------

    address public constant CRV_Deployer = 0xB9fC157394Af804a3578134A6585C0dc9cc990d4;  /// @dev CRV.FI deployer for meta-pools.
    address public constant _3CRV_BP = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;      /// @dev 3CRV 3Pool (DAI/USDC/USDT) for CRV Finance.
    address public constant _3CRV_TOKEN = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;   /// @dev 3CRV 3Pool LP token address.
    address public constant FRAX_3CRV_MP = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;  /// @dev 3CRV 3Pool LP token address.
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;           /// @dev The USDC stablecoin.
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;          /// @dev The FRAX stablecoin.
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;          /// @dev The USDC stablecoin.
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;          /// @dev The USDC stablecoin.

    address public ZVE_MP;          /// @dev To be determined upon pool deployment via constructor().
    address public immutable GBL;   /// @dev The ZivoeGlobals contract.

    uint256 public baseline;                /// @dev FRAX convertible, used for forwardYield() accounting.
    uint256 public nextYieldDistribution;   /// @dev Determines next available forwardYield() call.
    
    // -----------
    // Constructor
    // -----------

    /// @notice Initializes the OCL_ZVE_CRV_0.sol contract.
    /// @param DAO The administrator of this contract (intended to be ZivoeDAO).
    /// @param _GBL The ZivoeGlobals contract.
    constructor(
        address DAO,
        address _GBL
    ) {
        transferOwnership(DAO);
        GBL = _GBL;
        ZVE_MP = ICRVDeployer(CRV_Deployer).deploy_metapool(
            _3CRV_BP,                   /// The base-pool (3CRV = 3Pool).
            "ZVE_MetaPool_3CRV",        /// Name of meta-pool.
            "ZVE/3CRV",                 /// Symbol of meta-pool.
            IZivoeGlobals(_GBL).ZVE(),  /// Coin paired with base-pool. ($ZVE).
            250,                        /// Amplifier.
            20000000                    /// 0.20% fee.
        );
    }

    // ---------
    // Functions
    // ---------

    function canPullPartial() public override pure returns (bool) {
        return true;
    }

    function canPushMulti() public override pure returns (bool) {
        return true;
    }

    function canPullMulti() public override pure returns (bool) {
        return true;
    }

    /// @dev    This pulls capital from the DAO, does any necessary pre-conversions, and adds liquidity into ZVE MetaPool.
    /// @param  data Accompanying transaction data.
    function pushToLockerMulti(address[] calldata assets, uint256[] calldata amounts, bytes[] calldata data) external override onlyOwner {
        require(
            (assets[0] == DAI || assets[0] == USDC || assets[0] == USDT) && assets[1] == IZivoeGlobals(GBL).ZVE(),
            "OCL_ZVE_CRV_1::pushToLockerMulti() (assets[0] != DAI && assets[0] == USDC && assets[0] == USDT) || assets[1] != IZivoeGlobals(GBL).ZVE()"
        );
        
        for (uint256 i = 0; i < 2; i++) {
            IERC20(assets[i]).safeTransferFrom(owner(), address(this), amounts[i]);
        }
        if (nextYieldDistribution == 0) {
            nextYieldDistribution = block.timestamp + 30 days;
        }
        uint256 preBaseline;
        if (baseline != 0) {
            (preBaseline,) = FRAXConvertible();
        }
        // DAI || USDC || USDT, BasePool Deposit
        // 3CRV.coins(0) == DAI
        // 3CRV.coins(1) == USDC
        // 3CRV.coins(2) == USDT
        if (assets[0] == DAI) {
            IERC20(DAI).safeApprove(_3CRV_BP, IERC20(DAI).balanceOf(address(this)));
            uint256[3] memory deposits_bp;
            deposits_bp[0] = IERC20(DAI).balanceOf(address(this));
            ICRVPlainPool3CRV(_3CRV_BP).add_liquidity(deposits_bp, 0);
        }
        else if (assets[0] == USDC) {
            IERC20(USDC).safeApprove(_3CRV_BP, IERC20(USDC).balanceOf(address(this)));
            uint256[3] memory deposits_bp;
            deposits_bp[1] = IERC20(USDC).balanceOf(address(this));
            ICRVPlainPool3CRV(_3CRV_BP).add_liquidity(deposits_bp, 0);
        }
        else {
            IERC20(USDT).safeApprove(_3CRV_BP, IERC20(USDT).balanceOf(address(this)));
            uint256[3] memory deposits_bp;
            deposits_bp[2] = IERC20(USDT).balanceOf(address(this));
            ICRVPlainPool3CRV(_3CRV_BP).add_liquidity(deposits_bp, 0);
        }
        // 3CRV && ZVE, MetaPool Deposit
        // ZVE_MP.coins(0) == ZVE
        // ZVE_MP.coins(1) == 3CRV
        IERC20(_3CRV_TOKEN).safeApprove(ZVE_MP, IERC20(_3CRV_TOKEN).balanceOf(address(this)));
        IERC20(IZivoeGlobals(GBL).ZVE()).safeApprove(ZVE_MP, IERC20(IZivoeGlobals(GBL).ZVE()).balanceOf(address(this)));
        uint256[2] memory deposits_mp;
        deposits_mp[0] = IERC20(IZivoeGlobals(GBL).ZVE()).balanceOf(address(this));
        deposits_mp[1] = IERC20(_3CRV_TOKEN).balanceOf(address(this));
        ICRVMetaPool(ZVE_MP).add_liquidity(deposits_mp, 0);
        // Increase baseline.
        (uint256 postBaseline,) = FRAXConvertible();
        require(postBaseline > preBaseline, "OCL_ZVE_CRV_1::pushToLockerMulti() postBaseline < preBaseline");
        baseline = postBaseline - preBaseline;
    }

    /// @dev    This burns LP tokens from the ZVE MetaPool, and returns resulting coins back to the DAO.
    /// @param  assets The assets to return.
    /// @param  data Accompanying transaction data.
    function pullFromLockerMulti(address[] calldata assets, bytes[] calldata data) external override onlyOwner {
        require(
            assets[0] == DAI && assets[1] == USDC && assets[2] == USDT && assets[3] == IZivoeGlobals(GBL).ZVE(),
            "OCL_ZVE_CRV_1::pullFromLockerMulti() assets[0] != DAI || assets[1] != USDC || assets[2] != USDT || assets[3] != IZivoeGlobals(GBL).ZVE()"
        );
        
        uint256[2] memory tester;
        uint256[3] memory tester2;
        ICRVMetaPool(ZVE_MP).remove_liquidity(
            IERC20(ZVE_MP).balanceOf(address(this)), tester
        );
        ICRVPlainPool3CRV(_3CRV_BP).remove_liquidity(
            IERC20(_3CRV_TOKEN).balanceOf(address(this)), tester2
        );
        IERC20(DAI).safeTransfer(owner(), IERC20(DAI).balanceOf(address(this)));
        IERC20(USDC).safeTransfer(owner(), IERC20(USDC).balanceOf(address(this)));
        IERC20(USDT).safeTransfer(owner(), IERC20(USDT).balanceOf(address(this)));
        IERC20(IZivoeGlobals(GBL).ZVE()).safeTransfer(owner(), IERC20(IZivoeGlobals(GBL).ZVE()).balanceOf(address(this)));
        baseline = 0;
    }

    /// @dev    This burns a partial amount of LP tokens from the ZVE MetaPool, and returns resulting coins back to the DAO.
    /// @param  asset The LP token to burn.
    /// @param  amount The amount of LP tokens to burn.
    /// @param  data Accompanying transaction data.
    function pullFromLockerPartial(address asset, uint256 amount, bytes calldata data) external override onlyOwner {
        require(asset == ZVE_MP, "OCL_ZVE_CRV_0::pullFromLockerPartial() assets != ZVE_MP");

        uint256[2] memory tester;
        uint256[3] memory tester2;
        ICRVMetaPool(ZVE_MP).remove_liquidity(
            amount, tester
        );
        ICRVPlainPool3CRV(_3CRV_BP).remove_liquidity(
            IERC20(_3CRV_TOKEN).balanceOf(address(this)), tester2
        );
        IERC20(DAI).safeTransfer(owner(), IERC20(DAI).balanceOf(address(this)));
        IERC20(USDC).safeTransfer(owner(), IERC20(USDC).balanceOf(address(this)));
        IERC20(USDT).safeTransfer(owner(), IERC20(USDT).balanceOf(address(this)));
        IERC20(IZivoeGlobals(GBL).ZVE()).safeTransfer(owner(), IERC20(IZivoeGlobals(GBL).ZVE()).balanceOf(address(this)));
        baseline = 0;
    }

    /// @dev    This forwards yield to the YDL in the form of FRAX.
    function forwardYield() external {
        if (IZivoeGlobals(GBL).isKeeper(_msgSender())) {
            require(
                block.timestamp > nextYieldDistribution - 12 hours, 
                "OCL_ZVE_CRV_1::forwardYield() block.timestamp <= nextYieldDistribution - 12 hours"
            );
        }
        else {
            require(block.timestamp > nextYieldDistribution, "OCL_ZVE_CRV_1::forwardYield() block.timestamp <= nextYieldDistribution");
        }
        (uint256 amount, uint256 lp) = FRAXConvertible();
        require(amount > baseline, "OCL_ZVE_CRV_1::forwardYield() amount <= baseline");
        nextYieldDistribution = block.timestamp + 30 days;
        _forwardYield(amount, lp);
    }

    /// @dev Returns information on how much FRAX is convertible via current LP tokens.
    /// @return amount Current FRAX harvestable.
    /// @return lp Current ZVE_MP tokens.
    /// @notice The withdrawal mechanism is ZVE_3CRV_MP_TOKEN => 3CRV => Frax.
    function FRAXConvertible() public view returns (uint256 amount, uint256 lp) {
        lp = IERC20(ZVE_MP).balanceOf(address(this));
        amount = ICRVMetaPool(FRAX_3CRV_MP).calc_withdraw_one_coin(
            ICRVMetaPool(ZVE_MP).calc_withdraw_one_coin(lp, int128(1)), int128(0)
        );
    }

    function _forwardYield(uint256 amount, uint256 lp) private {
        uint256 lpBurnable = (amount - baseline) * lp / amount / 2; 
        ICRVMetaPool(ZVE_MP).remove_liquidity_one_coin(lpBurnable, 1, 0);
        IERC20(_3CRV_TOKEN).safeApprove(FRAX_3CRV_MP, IERC20(_3CRV_TOKEN).balanceOf(address(this)));
        ICRVMetaPool(FRAX_3CRV_MP).exchange(int128(1), int128(0), IERC20(_3CRV_TOKEN).balanceOf(address(this)), 0);
        IERC20(FRAX).safeTransfer(IZivoeGlobals(GBL).YDL(), IERC20(FRAX).balanceOf(address(this)));
        (baseline,) = FRAXConvertible();
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../Utility/ZivoeSwapper.sol";

import "../../ZivoeLocker.sol";

import "../../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

interface IZivoeGlobals_OCL_ZVE {
    /// @notice Returns the address of the Timelock contract.
    function TLC() external view returns (address);

    /// @notice Returns the address of the ZivoeYDL.sol contract.
    function YDL() external view returns (address);

    /// @notice Returns the address of the ZivoeToken.sol contract.
    function ZVE() external view returns (address);

    /// @notice Returns true if an address is whitelisted as a keeper.
    /// @return keeper Equals "true" if address is a keeper, "false" if not.
    function isKeeper(address) external view returns (bool keeper);
}

interface IZivoeYDL_OCL_ZVE {
    /// @notice Returns the "stablecoin" that will be distributed via YDL.
    /// @return asset The address of the "stablecoin" that will be distributed via YDL.
    function distributedAsset() external view returns (address asset);
}

interface IRouter_OCL_ZVE {
    /// @notice Adds liquidity in a pool with both ERC20 tokens A and B.
    /// @param tokenA A pool token.
    /// @param tokenB A pool token.
    /// @param amountADesired The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates).
    /// @param amountBDesired The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates).
    /// @param amountAMin Bounds the extent to which the B/A price can go up before the transaction reverts. Must be <= amountADesired.
    /// @param amountBMin Bounds the extent to which the A/B price can go up before the transaction reverts. Must be <= amountBDesired.
    /// @param to Recipient of the liquidity tokens.
    /// @param deadline Unix timestamp after which the transaction will revert.
    /// @return amountA The amount of tokenA sent to the pool.
    /// @return amountB The amount of tokenB sent to the pool.
    /// @return liquidity The amount of liquidity tokens minted.
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Removes liquidity in a pool with both ERC20 tokens A and B.
    /// @param tokenA A pool token.
    /// @param tokenB A pool token.
    /// @param liquidity The amount of liquidity tokens to remove.
    /// @param amountAMin The minimum amount of tokenA that must be received for the transaction not to revert.
    /// @param amountBMin The minimum amount of tokenB that must be received for the transaction not to revert.
    /// @param to Recipient of the underlying assets.
    /// @param deadline Unix timestamp after which the transaction will revert.
    /// @return amountA The amount of tokenA received.
    /// @return amountB The amount of tokenB received.
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

interface IFactory_OCL_ZVE {
    /// @notice Returns the address of the pair for tokenA and tokenB, if it has been created, else address(0).
    /// @param tokenA Address of one of pair's tokens.
    /// @param tokenB Address of pair's other token.
    /// @return pair The address of the pair.
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}



/// @notice This contract manages liquidity provisioning for a Uniswap v2 or Sushi pool.
///         This contract has the following responsibilities:
///           - Allocate capital to a $ZVE/pairAsset pool.
///           - Remove capital from a $ZVE/pairAsset pool.
///           - Forward yield (profits) every 30 days to the YDL with compounding mechanisms.
contract OCL_ZVE is ZivoeLocker, ZivoeSwapper, ReentrancyGuard {

    using SafeERC20 for IERC20;
    
    // ---------------------
    //    State Variables
    // ---------------------

    /// @dev Bool that determines whether to use Uniswap v2 or Sushi (true = Uniswap v2, false = Sushi).
    bool public uniswapOrSushi;

    address public immutable GBL;               /// @dev The ZivoeGlobals contract.

    address public pairAsset;                   /// @dev ERC20 that will be paired with $ZVE for Sushi pool.
    address public router;                      /// @dev Address for the Router (Uniswap v2 or Sushi).
    address public factory;                     /// @dev Aaddress for the Factory (Uniswap v2 or Sushi).

    uint256 public baseline;                    /// @dev FRAX convertible, used for forwardYield() accounting.
    uint256 public nextYieldDistribution;       /// @dev Determines next available forwardYield() call.
    uint256 public amountForConversion;         /// @dev The amount of stablecoin in this contract convertible and forwardable to YDL.

    uint256 public compoundingRateBIPS = 5000;  /// @dev The % of returns to retain, in BIPS.

    uint256 private constant BIPS = 10000;



    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the OCL_ZVE.sol contract.
    /// @param DAO The administrator of this contract (intended to be ZivoeDAO).
    /// @param _GBL The ZivoeGlobals contract.
    /// @param _pairAsset ERC20 that will be paired with $ZVE for pool.
    constructor(
        address DAO,
        address _GBL,
        address _pairAsset,
        bool _uniswapOrSushi
    ) {
        transferOwnership(DAO);
        GBL = _GBL;
        pairAsset = _pairAsset;
        uniswapOrSushi = _uniswapOrSushi;
        if (_uniswapOrSushi) {
            router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
            factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        }
        else {
            router = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
            factory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
        }
    }



    // ------------
    //    Events   
    // ------------

    /// @notice This event is emitted when updateCompoundingRateBIPS() is called.
    /// @param  oldValue The old value of compoundingRateBIPS.
    /// @param  newValue The new value of compoundingRateBIPS.
    event UpdatedCompoundingRateBIPS(uint256 oldValue, uint256 newValue);

    /// @notice Emitted during forwardYieldKeeper().
    /// @param  asset The "asset" being distributed.
    /// @param  amount The amount distributed.
    event YieldForwarded(address indexed asset, uint256 amount);



    // ---------------
    //    Functions
    // ---------------

    /// @notice Permission for owner to call pushToLockerMulti().
    function canPushMulti() public override pure returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLocker().
    function canPull() public override pure returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLockerPartial().
    function canPullPartial() public override pure returns (bool) {
        return true;
    }

    /// @notice This pulls capital from the DAO and adds liquidity into a $ZVE/pairAsset pool.
    /// @param  assets The assets to pull from the DAO.
    /// @param  amounts The amount to pull of each asset respectively.
    /// @param  data Accompanying transaction data.
    function pushToLockerMulti(address[] calldata assets, uint256[] calldata amounts, bytes[] calldata data) external override onlyOwner nonReentrant {
        require(
            assets[0] == pairAsset && assets[1] == IZivoeGlobals_OCL_ZVE(GBL).ZVE(),
            "OCL_ZVE::pushToLockerMulti() assets[0] != pairAsset || assets[1] != IZivoeGlobals_OCL_ZVE(GBL).ZVE()"
        );

        for (uint256 i = 0; i < 2; i++) {
            require(amounts[i] >= 10 * 10**6, "OCL_ZVE::pushToLockerMulti() amounts[i] < 10 * 10**6");
            IERC20(assets[i]).safeTransferFrom(owner(), address(this), amounts[i]);
        }

        if (nextYieldDistribution == 0) {
            nextYieldDistribution = block.timestamp + 30 days;
        }

        uint256 preBaseline;
        if (baseline != 0) {
            (preBaseline,) = pairAssetConvertible();
        }

        // Router addLiquidity() endpoint.
        IERC20(pairAsset).safeApprove(router, IERC20(pairAsset).balanceOf(address(this)));
        IERC20(IZivoeGlobals_OCL_ZVE(GBL).ZVE()).safeApprove(router, IERC20(IZivoeGlobals_OCL_ZVE(GBL).ZVE()).balanceOf(address(this)));
        IRouter_OCL_ZVE(router).addLiquidity(
            pairAsset, 
            IZivoeGlobals_OCL_ZVE(GBL).ZVE(), 
            IERC20(pairAsset).balanceOf(address(this)),
            IERC20(IZivoeGlobals_OCL_ZVE(GBL).ZVE()).balanceOf(address(this)),
            IERC20(pairAsset).balanceOf(address(this)),
            IERC20(IZivoeGlobals_OCL_ZVE(GBL).ZVE()).balanceOf(address(this)),
            address(this),
            block.timestamp + 14 days
        );
        assert(IERC20(pairAsset).allowance(address(this), router) == 0);
        assert(IERC20(IZivoeGlobals_OCL_ZVE(GBL).ZVE()).allowance(address(this), router) == 0);

        // Increase baseline.
        (uint256 postBaseline,) = pairAssetConvertible();
        require(postBaseline > preBaseline, "OCL_ZVE::pushToLockerMulti() postBaseline < preBaseline");
        baseline = postBaseline - preBaseline;
    }

    /// @notice This burns LP tokens from the $ZVE/pairAsset pool and returns them to the DAO.
    /// @param  asset The asset to burn.
    /// @param  data Accompanying transaction data.
    function pullFromLocker(address asset, bytes calldata data) external override onlyOwner nonReentrant {
        address pair = IFactory_OCL_ZVE(factory).getPair(pairAsset, IZivoeGlobals_OCL_ZVE(GBL).ZVE());
        
        // "pair" represents the liquidity pool token (minted, burned).
        // "pairAsset" represents the stablecoin paired against $ZVE.
        if (asset == pair) {
            IERC20(pair).safeApprove(router, IERC20(pair).balanceOf(address(this)));
            IRouter_OCL_ZVE(router).removeLiquidity(
                pairAsset, 
                IZivoeGlobals_OCL_ZVE(GBL).ZVE(), 
                IERC20(pair).balanceOf(address(this)), 
                0, 
                0,
                address(this),
                block.timestamp + 14 days
            );
            assert(IERC20(pair).allowance(address(this), router) == 0);

            IERC20(pairAsset).safeTransfer(owner(), IERC20(pairAsset).balanceOf(address(this)));
            IERC20(IZivoeGlobals_OCL_ZVE(GBL).ZVE()).safeTransfer(owner(), IERC20(IZivoeGlobals_OCL_ZVE(GBL).ZVE()).balanceOf(address(this)));
            baseline = 0;
        }
        else if (asset == pairAsset) {
            IERC20(asset).safeTransfer(owner(), IERC20(asset).balanceOf(address(this)));
            amountForConversion = 0;
        }
        else {
            IERC20(asset).safeTransfer(owner(), IERC20(asset).balanceOf(address(this)));
        }
    }

    /// @notice This burns LP tokens from the $ZVE/pairAsset pool and returns them to the DAO.
    /// @param  asset The asset to burn.
    /// @param  amount The amount of "asset" to burn.
    /// @param  data Accompanying transaction data.
    function pullFromLockerPartial(address asset, uint256 amount, bytes calldata data) external override onlyOwner nonReentrant {
        address pair = IFactory_OCL_ZVE(factory).getPair(pairAsset, IZivoeGlobals_OCL_ZVE(GBL).ZVE());
        
        // "pair" represents the liquidity pool token (minted, burned).
        // "pairAsset" represents the stablecoin paired against $ZVE.
        if (asset == pair) {
            IERC20(pair).safeApprove(router, amount);
            IRouter_OCL_ZVE(router).removeLiquidity(
                pairAsset, 
                IZivoeGlobals_OCL_ZVE(GBL).ZVE(), 
                amount, 
                0, 
                0,
                address(this),
                block.timestamp + 14 days
            );
            assert(IERC20(pair).allowance(address(this), router) == 0);
            
            IERC20(pairAsset).safeTransfer(owner(), IERC20(pairAsset).balanceOf(address(this)));
            IERC20(IZivoeGlobals_OCL_ZVE(GBL).ZVE()).safeTransfer(owner(), IERC20(IZivoeGlobals_OCL_ZVE(GBL).ZVE()).balanceOf(address(this)));
            (baseline,) = pairAssetConvertible();
        }
        else if (asset == pairAsset) {
            IERC20(asset).safeTransfer(owner(), amount);
            amountForConversion = IERC20(pairAsset).balanceOf(address(this));
        }
        else {
            IERC20(asset).safeTransfer(owner(), amount);
        }
    }

    /// @notice Updates the compounding rate of this contract.
    /// @dev    A value of 2,000 represent 20% of the earnings stays in this contract, compounding.
    /// @param  _compoundingRateBIPS The new compounding rate value.
    function updateCompoundingRateBIPS(uint256 _compoundingRateBIPS) external {
        require(
            _msgSender() == IZivoeGlobals_OCL_ZVE(GBL).TLC(), 
            "OCL_ZVE::updateCompoundingRateBIPS() _msgSender() != IZivoeGlobals_OCL_ZVE(GBL).TLC()"
        );
        require(_compoundingRateBIPS <= BIPS, "OCL_ZVE::updateCompoundingRateBIPS() ratio > BIPS");

        emit UpdatedCompoundingRateBIPS(compoundingRateBIPS, _compoundingRateBIPS);
        compoundingRateBIPS = _compoundingRateBIPS;
    }

    /// @notice This function converts and forwards available "amountForConversion" to YDL.distributeAsset().
    /// @param data The data retrieved from 1inch API in order to execute the swap.
    function forwardYieldKeeper(bytes calldata data) external nonReentrant {
        require(IZivoeGlobals_OCL_ZVE(GBL).isKeeper(_msgSender()), "OCL_ZVE::forwardYieldKeeper() !IZivoeGlobals_OCL_ZVE(GBL).isKeeper(_msgSender())");
        address _toAsset = IZivoeYDL_OCL_ZVE(IZivoeGlobals_OCL_ZVE(GBL).YDL()).distributedAsset();
        require(_toAsset != pairAsset, "OCL_ZVE::forwardYieldKeeper() _toAsset == pairAsset");

        // Swap available "amountForConversion" from stablecoin to YDL.distributedAsset().
        convertAsset(pairAsset, _toAsset, amountForConversion, data);

        emit YieldForwarded(_toAsset, IERC20(_toAsset).balanceOf(address(this)));
        
        // Transfer all _toAsset received to the YDL, then reduce amountForConversion to 0.
        IERC20(_toAsset).safeTransfer(IZivoeGlobals_OCL_ZVE(GBL).YDL(), IERC20(_toAsset).balanceOf(address(this)));
        amountForConversion = 0;
    }

    /// @notice This forwards yield to the YDL in the form of pairAsset.
    function forwardYield() external {
        if (IZivoeGlobals_OCL_ZVE(GBL).isKeeper(_msgSender())) {
            require(
                block.timestamp > nextYieldDistribution - 12 hours, 
                "OCL_ZVE::forwardYield() block.timestamp <= nextYieldDistribution - 12 hours"
            );
        }
        else {
            require(block.timestamp > nextYieldDistribution, "OCL_ZVE::forwardYield() block.timestamp <= nextYieldDistribution");
        }

        (uint256 amount, uint256 lp) = pairAssetConvertible();
        require(amount > baseline, "OCL_ZVE::forwardYield() amount <= baseline");
        nextYieldDistribution = block.timestamp + 30 days;
        _forwardYield(amount, lp);
    }

    /// @notice This forwards yield to the YDL in the form of pairAsset.
    /// @dev    Private function, only callable via forwardYield().
    /// @param  amount Current pairAsset harvestable.
    /// @param  lp Current ZVE/pairAsset LP tokens.
    function _forwardYield(uint256 amount, uint256 lp) private nonReentrant {
        uint256 lpBurnable = (amount - baseline) * lp / amount * compoundingRateBIPS / BIPS;
        address pair = IFactory_OCL_ZVE
        (factory).getPair(pairAsset, IZivoeGlobals_OCL_ZVE(GBL).ZVE());
        IERC20(pair).safeApprove(router, lpBurnable);
        IRouter_OCL_ZVE(router).removeLiquidity(
            pairAsset,
            IZivoeGlobals_OCL_ZVE(GBL).ZVE(),
            lpBurnable,
            0,
            0,
            address(this),
            block.timestamp + 14 days
        );
        assert(IERC20(pair).allowance(address(this), router) == 0);
        if (pairAsset != IZivoeYDL_OCL_ZVE(IZivoeGlobals_OCL_ZVE(GBL).YDL()).distributedAsset()) {
            amountForConversion = IERC20(pairAsset).balanceOf(address(this));
        }
        else {
            emit YieldForwarded(pairAsset, IERC20(pairAsset).balanceOf(address(this)));
            IERC20(pairAsset).safeTransfer(IZivoeGlobals_OCL_ZVE(GBL).YDL(), IERC20(pairAsset).balanceOf(address(this)));
        }
        IERC20(IZivoeGlobals_OCL_ZVE(GBL).ZVE()).safeTransfer(owner(), IERC20(IZivoeGlobals_OCL_ZVE(GBL).ZVE()).balanceOf(address(this)));
        (baseline,) = pairAssetConvertible();
    }

    /// @notice Returns information on how much pairAsset is convertible via current LP tokens.
    /// @dev    The withdrawal mechanism is ZVE/pairAsset_LP => pairAsset.
    /// @return amount Current pairAsset harvestable.
    /// @return lp Current ZVE/pairAsset LP tokens.
    function pairAssetConvertible() public view returns (uint256 amount, uint256 lp) {
        address pair = IFactory_OCL_ZVE(factory).getPair(pairAsset, IZivoeGlobals_OCL_ZVE(GBL).ZVE());
        uint256 balance_pairAsset = IERC20(pairAsset).balanceOf(pair);
        uint256 totalSupply_PAIR = IERC20(pair).totalSupply();
        lp = IERC20(pair).balanceOf(address(this));
        amount = lp * balance_pairAsset / totalSupply_PAIR;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../../ZivoeLocker.sol";

import { ICRV_PP_128_NP, ICRV_MP_256, ILendingPool, IZivoeGlobals } from "../../../misc/InterfacesAggregated.sol";

/// @dev    This contract is responsible for allocating capital to AAVE (v2).
contract OCY_AAVE is ZivoeLocker {

    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    address public immutable GBL;  /// @dev The ZivoeGlobals contract.

    /// @dev Stablecoin addresses.
    address public constant DAI  = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// @dev CRV.FI pool addresses (plain-pool, and meta-pool).
    address public constant CRV_PP = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant FRAX3CRV_MP = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;

    /// @dev AAVE v2 addresses.
    address public constant AAVE_V2_LendingPool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address public constant AAVE_V2_aUSDC = 0xBcca60bB61934080951369a648Fb03DF4F96263C;

    uint256 baseline;
    uint256 nextYieldDistribution;


    
    // -----------
    // Constructor
    // -----------

    /// @notice Initializes the OCY_AAVE.sol contract.
    /// @param DAO The administrator of this contract (intended to be ZivoeDAO).
    /// @param _GBL The ZivoeGlobals contract.
    constructor(address DAO, address _GBL) {
        transferOwnership(DAO);
        GBL = _GBL;
    }


    // ---------
    // Functions
    // ---------

    function canPush() public override pure returns (bool) {
        return true;
    }

    function canPull() public override pure returns (bool) {
        return true;
    }

    function canPullPartial() public override pure returns (bool) {
        return true;
    }

    /// @dev    This pulls capital from the DAO, does any necessary pre-conversions, and invests into AAVE v2 (USDC pool).
    /// @param  data Accompanying transaction data.
    function pushToLocker(address asset, uint256 amount, bytes calldata data) external override onlyOwner {

        require(amount > 0, "OCY_AAVE::pushToLocker() amount == 0");

        nextYieldDistribution = block.timestamp + 30 days;

        IERC20(asset).safeTransferFrom(owner(), address(this), amount);

        if (asset == USDC) {
            _invest();
        }
        else {
            if (asset == DAI) {
                // Convert DAI to USDC via 3CRV pool.
                IERC20(asset).safeApprove(CRV_PP, IERC20(asset).balanceOf(address(this)));
                ICRV_PP_128_NP(CRV_PP).exchange(0, 1, IERC20(asset).balanceOf(address(this)), 0);
                _invest();
            }
            else if (asset == USDT) {
                // Convert USDT to USDC via 3CRV pool.
                IERC20(asset).safeApprove(CRV_PP, IERC20(asset).balanceOf(address(this)));
                ICRV_PP_128_NP(CRV_PP).exchange(int128(2), int128(1), IERC20(asset).balanceOf(address(this)), 0);
                _invest();
            }
            else if (asset == FRAX) {
                // Convert FRAX to USDC via FRAX/3CRV meta-pool.
                IERC20(asset).safeApprove(FRAX3CRV_MP, IERC20(asset).balanceOf(address(this)));
                ICRV_MP_256(FRAX3CRV_MP).exchange_underlying(int128(0), int128(2), IERC20(asset).balanceOf(address(this)), 0);
                _invest();
            }
            else {
                /// @dev Revert here, given unknown "asset" received (otherwise, "asset" will be locked and/or lost forever).
                revert("OCY_AAVE.sol::pushToLocker() asset not supported"); 
            }
        }
    }

    /// @dev    This divests allocation from AAVE v2 (USDC pool) and returns capital to the DAO.
    /// @param  asset The asset to return (in this case, required to be USDC).
    /// @param  data Accompanying transaction data.
    function pullFromLocker(address asset, bytes calldata data) external override onlyOwner {
        require(asset == USDC, "OCY_AAVE::pullFromLocker() asset != USDC");
        _divest();
    }

    /// @dev    This divests allocation from AAVE v2 (USDC pool) and returns capital to the DAO.
    /// @param  asset The asset to return (in this case, required to be USDC).
    /// @param  amount The amount of "asset" to return.
    /// @param  data Accompanying transaction data.
    function pullFromLockerPartial(address asset, uint256 amount, bytes calldata data) external override onlyOwner {
        require(asset == USDC, "OCY_AAVE::pullFromLocker() asset != USDC");
        _divestSpecific(amount);
    }

    /// @dev    This forwards yield to the YDL (according to specific conditions as will be discussed).
    function forwardYield() external {
        require(block.timestamp > nextYieldDistribution, "OCY_AAVE::forwardYield() block.timestamp <= nextYieldDistribution");
        nextYieldDistribution = block.timestamp + 30 days;
        _forwardYield();
        baseline = IERC20(AAVE_V2_aUSDC).balanceOf(address(this));
    }

    function _forwardYield() private {
        uint256 currentBalance = IERC20(AAVE_V2_aUSDC).balanceOf(address(this));
        uint256 difference = currentBalance - baseline;
        ILendingPool(AAVE_V2_LendingPool).withdraw(USDC, difference, address(this));
        IERC20(USDC).safeApprove(FRAX3CRV_MP, IERC20(USDC).balanceOf(address(this)));
        ICRV_MP_256(FRAX3CRV_MP).exchange_underlying(int128(2), int128(0), IERC20(USDC).balanceOf(address(this)), 0);
        IERC20(FRAX).safeApprove(IZivoeGlobals(GBL).YDL(), IERC20(FRAX).balanceOf(address(this)));
    }

    /// @dev    This directs USDC into the AAVE v2 lending protocol.
    /// @notice Private function, should only be called through pushToLocker() which can only be called by DAO.
    function _invest() private {
        baseline += IERC20(USDC).balanceOf(address(this));
        IERC20(USDC).safeApprove(AAVE_V2_LendingPool, IERC20(USDC).balanceOf(address(this)));
        ILendingPool(AAVE_V2_LendingPool).deposit(USDC, IERC20(USDC).balanceOf(address(this)), address(this), uint16(0));
    }

    /// @dev    This removes USDC from the AAVE lending protocol.
    /// @notice Private function, should only be called through pullFromLocker() which can only be called by DAO.
    function _divest() private {
        ILendingPool(AAVE_V2_LendingPool).withdraw(USDC, type(uint256).max, IZivoeGlobals(GBL).DAO());
        baseline = 0;
    }

    /// @dev    This removes USDC from the AAVE lending protocol.
    /// @notice Private function, should only be called through pullFromLockerPartial() which can only be called by DAO.
    function _divestSpecific(uint256 amount) private {
        ILendingPool(AAVE_V2_LendingPool).withdraw(USDC, amount, IZivoeGlobals(GBL).DAO());
        baseline = 0;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../../ZivoeLocker.sol";
import "../../Utility/ZivoeSwapper.sol";

import {
    ICRVPlainPoolFBP, 
    IZivoeGlobals, 
    ICRVMetaPool, 
    ICVX_Booster, 
    IConvexRewards, 
    IZivoeYDL, 
    AggregatorV3Interface
} from "../../../misc/InterfacesAggregated.sol";

interface IZivoeGlobals_P_4 {
    function YDL() external view returns (address);
    function isKeeper(address) external view returns (bool);
    function standardize(uint256, address) external view returns (uint256);
}

interface IZivoeYDL_P_3 {
    function distributedAsset() external view returns (address);
}

/// @dev    This contract aims at deploying lockers that will invest in Convex pools. 
///         Plain pools should contain only stablecoins denominated in same currency (all tokens in USD or all tokens in EUR for example, otherwise USD_Convertible won't be correct)

contract e_OCY_CVX_Modular is ZivoeLocker, ZivoeSwapper {
    
    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    address public immutable GBL; /// @dev The ZivoeGlobals contract.
    uint256 public nextYieldDistribution;     /// @dev Determines next available forwardYield() call. 
    uint256 public investTimeLock; /// @dev defines a period for keepers to invest before public accessible function.
    bool public metaOrPlainPool;  /// @dev If true = metapool, if false = plain pool
    bool public extraRewards;     /// @dev If true, extra rewards are distributed on top of CRV and CVX. If false, no extra rewards.
    uint256 public baseline;      /// @dev USD convertible, used for forwardYield() accounting.
    uint256 public yieldOwedToYDL; /// @dev Part of LP token increase over baseline that is owed to the YDL (needed for accounting when pulling or investing capital)
    uint256 public toForwardCRV; /// @dev CRV tokens harvested that need to be transfered by ZVL to the YDL.
    uint256 public toForwardCVX; /// @dev CVX tokens harvested that need to be transfered by ZVL to the YDL.
    uint256[] public toForwardExtraRewards; /// @dev Extra rewards harvested that need to be transfered by ZVL to the YDL.
    uint256[] public toForwardTokensBaseline; /// @dev LP tokens harvested that need to be transfered by ZVL to the YDL.


    /// @dev Convex addresses.
    address public CVX_Deposit_Address;
    address public CVX_Reward_Address;

    /// @dev Convex staking pool ID.
    uint256 public convexPoolID;

    /// @dev Reward addresses.
    ///TODO: could optimize with including CVX and CRV in "rewardsAddresses", to check.
    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address[] public rewardsAddresses;

    /// @dev Curve addresses:
    address public pool;
    address public POOL_LP_TOKEN;

    /// @dev Metapool parameters:
    ///Not able to find a method to determine which of both coins(0,1) is the BASE_TOKEN, thus has to be specified in constructor
    address public BASE_TOKEN;
    address public MP_UNDERLYING_LP_TOKEN;
    address public MP_UNDERLYING_LP_POOL;
    ///Needed to calculate the LP price of the underlying LP Token
    uint8 public numberOfTokensUnderlyingLPPool;
    int128 public indexBASE_TOKEN;

    /// @dev Plain Pool parameters:
    address[] public PP_TOKENS; 

    /// @dev chainlink price feeds:
    address[] public chainlinkPriceFeeds;

    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the e_OCY_CVX_Modular.sol contract.
    /// @param _ZivoeAddresses _ZivoeAddresses[0] = The administrator of this contract (intended to be ZivoeDAO) and _ZivoeAddresses[1] = GBL (the ZivoeGlobals contract).
    /// @param _boolMetaOrPlainAndRewards _boolMetaOrPlainAndRewards[0] => If true: metapool, if false: plain pool. _boolMetaOrPlainAndRewards[1] => if true: extra rewards distributed on top of CRV or CVX.
    /// @param _curvePool address of the Curve Pool.
    /// @param _CVX_Deposit_Address address of the convex Booster contract.
    /// @param _rewardsAddresses addresses of the extra rewards. If _extraRewards = false set as an array of the zero address.
    /// @param _BASE_TOKEN_MP if metapool should specify the address of the base token of the pool. If plain pool, set to the zero address.
    /// @param _MP_UNDERLYING_LP_POOL if metapool specify address of the underlying LP token's pool (3CRV for example).
    /// @param _numberOfTokensUnderlyingLPPool if metapool: specify the number of tokens in the underlying LP pool (for 3CRV pool set to 3). If plain pool: set to 0.
    /// @param _numberOfTokensPP If pool is a metapool, set to 0. If plain pool, specify the number of coins in the pool.
    /// @param _convexPoolID Indicate the ID of the Convex pool where the LP token should be staked.
    /// @param _chainlinkPriceFeeds array containing the addresses of the chainlink price feeds, should be provided in correct order (refer to coins index in Curve pool)

    constructor(
        address[] memory _ZivoeAddresses,  
        bool[] memory _boolMetaOrPlainAndRewards, 
        address _curvePool, 
        address _CVX_Deposit_Address, 
        address[] memory _rewardsAddresses, 
        address _BASE_TOKEN_MP, 
        address _MP_UNDERLYING_LP_POOL,
        uint8 _numberOfTokensUnderlyingLPPool,
        uint8 _numberOfTokensPP, 
        uint256 _convexPoolID,
        address[] memory _chainlinkPriceFeeds) {

        require(_numberOfTokensPP < 5, "e_OCY_CVX_Modular::constructor() max 4 tokens in plain pool");
        require(_rewardsAddresses.length < 5, "e_OCY_CVX_Modular::constructor() max 4 reward tokens");
        require(_numberOfTokensUnderlyingLPPool < 5, "e_OCY_CVX_Modular::constructor() max 4 tokens in underlying LP pool");

        transferOwnership(_ZivoeAddresses[0]);
        GBL = _ZivoeAddresses[1];
        CVX_Deposit_Address = _CVX_Deposit_Address;
        CVX_Reward_Address = ICVX_Booster(_CVX_Deposit_Address).poolInfo(_convexPoolID).crvRewards;
        metaOrPlainPool = _boolMetaOrPlainAndRewards[0];
        convexPoolID = _convexPoolID;
        extraRewards = _boolMetaOrPlainAndRewards[1];
        numberOfTokensUnderlyingLPPool = _numberOfTokensUnderlyingLPPool;


        ///init rewards (other than CVX and CRV)
        if (extraRewards == true) {
            for (uint8 i = 0; i < _rewardsAddresses.length; i++) {
                rewardsAddresses.push(_rewardsAddresses[i]);
            }
        }    

        if (metaOrPlainPool == true) {
            require(_chainlinkPriceFeeds.length == (1 + numberOfTokensUnderlyingLPPool) , "e_OCY_CVX_Modular::constructor() no correct amount of price feeds for metapool");
            pool = _curvePool;
            POOL_LP_TOKEN = ICVX_Booster(_CVX_Deposit_Address).poolInfo(_convexPoolID).lptoken;
            BASE_TOKEN = _BASE_TOKEN_MP;
            MP_UNDERLYING_LP_POOL = _MP_UNDERLYING_LP_POOL;
        
            for (uint8 i = 0; i < _chainlinkPriceFeeds.length; i++) {
                chainlinkPriceFeeds.push(_chainlinkPriceFeeds[i]);
            }
            if (ICRVMetaPool(pool).coins(0) == _BASE_TOKEN_MP) {
                MP_UNDERLYING_LP_TOKEN = ICRVMetaPool(pool).coins(1);
                indexBASE_TOKEN = 0;
            } else if (ICRVMetaPool(pool).coins(1) == _BASE_TOKEN_MP) {
                MP_UNDERLYING_LP_TOKEN = ICRVMetaPool(pool).coins(0);
                indexBASE_TOKEN = 1;
            }

        }

        if (metaOrPlainPool == false) {
            require(_chainlinkPriceFeeds.length == _numberOfTokensPP, "e_OCY_CVX_Modular::constructor() plain pool: number of price feeds should correspond to number of tokens");
            pool = _curvePool;
            POOL_LP_TOKEN = ICVX_Booster(_CVX_Deposit_Address).poolInfo(_convexPoolID).lptoken;

            ///init tokens of the plain pool and sets chainlink price feeds.
            ///TODO: check if possible to require that price feeds submitted in right order.
            for (uint8 i = 0; i < _numberOfTokensPP; i++) {
                PP_TOKENS.push(ICRVPlainPoolFBP(pool).coins(i));
                chainlinkPriceFeeds.push(_chainlinkPriceFeeds[i]);
            }
        }
    }

    // ---------------
    //    Functions
    // ---------------

    function canPushMulti() public pure override returns (bool) {
        return true;
    }

    function canPullMulti() public pure override returns (bool) {
        return true;
    }

    function canPullPartial() public override pure returns (bool) {
        return true;
    }

    function pushToLockerMulti(
        address[] memory assets, 
        uint256[] memory amounts,
        bytes[] calldata data
    ) public override onlyOwner {
        require(
            assets.length <= 4, 
            "e_OCY_CVX_Modular::pushToLocker() assets.length > 4"
        );
        for (uint256 i = 0; i < assets.length; i++) {
            if (amounts[i] > 0) {
                IERC20(assets[i]).safeTransferFrom(owner(), address(this), amounts[i]);
            }
        }

        /// Gives keepers time to convert the stablecoins to the Curve pool assets.
        investTimeLock = block.timestamp + 24 hours;
    }   

    /// @dev    This divests allocation from Convex and Curve pool and returns capital to the DAO.
    /// @notice Only callable by the DAO.
    /// @param  assets The assets to return.
    /// TODO: check for duplicate assets + should we use the assets parameter ? + Check rewards in the future in tests.
    function pullFromLockerMulti(address[] calldata assets, bytes[] calldata data) public override onlyOwner {

        if (metaOrPlainPool == true) {
            /// We verify that the asset out is equal to the BASE_TOKEN.
            require(assets[0] == BASE_TOKEN && assets.length == 1, "e_OCY_CVX_Modular::pullFromLockerMulti() asset not equal to BASE_TOKEN");

            IConvexRewards(CVX_Reward_Address).withdrawAllAndUnwrap(true);
            ICRVMetaPool(pool).remove_liquidity_one_coin(IERC20(POOL_LP_TOKEN).balanceOf(address(this)), indexBASE_TOKEN, 0);
            IERC20(BASE_TOKEN).safeTransfer(owner(), IERC20(BASE_TOKEN).balanceOf(address(this)));

        }

        if (metaOrPlainPool == false) {
            /// We verify that the assets out are equal to the PP_TOKENS.
            for (uint8 i = 0; i < PP_TOKENS.length; i++) {
                require(assets[i] == PP_TOKENS[i], "e_OCY_CVX_Modular::pullFromLockerMulti() assets input array should be equal to PP_TOKENS array and in the same order" );
            }
            
            IConvexRewards(CVX_Reward_Address).withdrawAllAndUnwrap(true);

            removeLiquidityPlainPool(true);

        }

        if (IERC20(CRV).balanceOf(address(this)) > 0) {
            IERC20(CRV).safeTransfer(owner(), IERC20(CRV).balanceOf(address(this)));
        }

        if (IERC20(CVX).balanceOf(address(this)) > 0) {
            IERC20(CVX).safeTransfer(owner(), IERC20(CVX).balanceOf(address(this)));
        }

        if (extraRewards == true) {
            for (uint8 i = 0; i < rewardsAddresses.length; i++) {
                if (IERC20(rewardsAddresses[i]).balanceOf(address(this)) > 0) {
                    IERC20(rewardsAddresses[i]).safeTransfer(owner(), IERC20(rewardsAddresses[i]).balanceOf(address(this)));
                }        
            }
        }

        baseline = 0;

    }

    /// @dev    This burns a partial amount of LP tokens from the Convex FRAX-USDC staking pool,
    ///         removes the liquidity from Curve and returns resulting coins back to the DAO.
    /// @notice Only callable by the DAO.
    /// @param  convexRewardAddress The Convex contract to call to withdraw LP tokens.
    /// @param  amount The amount of LP tokens to burn.
    function pullFromLockerPartial(address convexRewardAddress, uint256 amount, bytes calldata data) external override onlyOwner {
        require(convexRewardAddress == CVX_Reward_Address, "e_OCY_CVX_Modular::pullFromLockerPartial() convexRewardAddress != CVX_Reward_Address");
        require(amount < IERC20(CVX_Reward_Address).balanceOf(address(this)) && amount > 0, "e_OCY_CVX_Modular::pullFromLockerPartial() LP token amount to withdraw should be less than locker balance and greater than 0");

        //Accounts for interest that should be redistributed to YDL
        if (USD_Convertible() > baseline) {
            yieldOwedToYDL += USD_Convertible() - baseline;

        }

        IConvexRewards(CVX_Reward_Address).withdrawAndUnwrap(amount, false);

        if (metaOrPlainPool == true) {
            
            ICRVMetaPool(pool).remove_liquidity_one_coin(IERC20(POOL_LP_TOKEN).balanceOf(address(this)), indexBASE_TOKEN, 0);
            IERC20(BASE_TOKEN).safeTransfer(owner(), IERC20(BASE_TOKEN).balanceOf(address(this)));

        }

        if (metaOrPlainPool == false) {
            removeLiquidityPlainPool(true);
        }

        baseline = USD_Convertible();
    }

    /// @dev    This will remove liquidity from Curve Plain Pools and transfer the tokens to the DAO.
    /// @notice Private function, should only be called through pullFromLockerMulti() and pullFromLockerPartial().
    function removeLiquidityPlainPool(bool _transfer) private {

        if (PP_TOKENS.length == 2) {
            uint256[2] memory minAmountsOut;
            ICRVPlainPoolFBP(pool).remove_liquidity(IERC20(POOL_LP_TOKEN).balanceOf(address(this)), minAmountsOut);
        }

        if (PP_TOKENS.length == 3) {
            uint256[3] memory minAmountsOut;
            ICRVPlainPoolFBP(pool).remove_liquidity(IERC20(POOL_LP_TOKEN).balanceOf(address(this)), minAmountsOut);
        }

        if (PP_TOKENS.length == 4) {
            uint256[4] memory minAmountsOut;
            ICRVPlainPoolFBP(pool).remove_liquidity(IERC20(POOL_LP_TOKEN).balanceOf(address(this)), minAmountsOut);
        } 

        if (_transfer == true) {
            for (uint8 i = 0; i < PP_TOKENS.length; i++) {
                if (IERC20(PP_TOKENS[i]).balanceOf(address(this)) > 0) {
                    IERC20(PP_TOKENS[i]).safeTransfer(owner(), IERC20(PP_TOKENS[i]).balanceOf(address(this)));
                }       
            }
        }  
    }


    ///@dev give Keepers a way to pre-convert assets via 1INCH
    function keeperConvertStablecoin(
        address stablecoin,
        address assetOut,
        bytes calldata data
    ) public {
        require(IZivoeGlobals(GBL).isKeeper(_msgSender()));

        if (metaOrPlainPool == true) {
            /// We verify that the asset out is equal to the BASE_TOKEN.
            require(assetOut == BASE_TOKEN && stablecoin != assetOut);
        }

        if (metaOrPlainPool == false) {
            bool assetOutIsCorrect;
            for (uint8 i = 0; i < PP_TOKENS.length; i++) {
                if (PP_TOKENS[i] == assetOut) {
                    assetOutIsCorrect = true;
                    break;
                }
            }
            require(assetOutIsCorrect == true && stablecoin != assetOut);
        }

        IERC20(stablecoin).safeApprove(router1INCH_V4, IERC20(stablecoin).balanceOf(address(this)));
    
        convertAsset(stablecoin, assetOut, IERC20(stablecoin).balanceOf(address(this)), data);

        /// Once the keepers have started converting stablecoins, allow them 12 hours to invest those assets.
        investTimeLock = block.timestamp + 12 hours;
    } 

    /// @dev  This directs tokens into a Curve Pool and then stakes the LP into Convex.
    function invest() public {
        /// TODO validate baseline when depegging coins with chainlink taking the lowest price for calculation
        if (!IZivoeGlobals(GBL).isKeeper(_msgSender())) {
            require(investTimeLock < block.timestamp, "timelock - restricted to keepers for now" );
        }

        uint256 preBaseline;

        if (baseline != 0) {
            preBaseline = USD_Convertible();
            if (preBaseline > baseline) {
                yieldOwedToYDL += preBaseline - baseline;
            }
        }    

        if (nextYieldDistribution == 0) {
            nextYieldDistribution = block.timestamp + 30 days;
        } 

        if (metaOrPlainPool == true) {
            
            uint256[2] memory deposits_mp;

            if (ICRVMetaPool(pool).coins(0) == BASE_TOKEN) {
                deposits_mp[0] = IERC20(BASE_TOKEN).balanceOf(address(this));
            } else if (ICRVMetaPool(pool).coins(1) == BASE_TOKEN) {
                deposits_mp[1] = IERC20(BASE_TOKEN).balanceOf(address(this));
            }
            IERC20(BASE_TOKEN).safeApprove(pool, IERC20(BASE_TOKEN).balanceOf(address(this)));
            ICRVMetaPool(pool).add_liquidity(deposits_mp, 0);

        }

        if (metaOrPlainPool == false) {

            if (PP_TOKENS.length == 2) {
                uint256[2] memory deposits_pp;

                for (uint8 i = 0; i < PP_TOKENS.length; i++) {
                    deposits_pp[i] = IERC20(PP_TOKENS[i]).balanceOf(address(this));
                    if (IERC20(PP_TOKENS[i]).balanceOf(address(this)) > 0) {
                        IERC20(PP_TOKENS[i]).safeApprove(pool, IERC20(PP_TOKENS[i]).balanceOf(address(this)));
                    }

                }

                ICRVPlainPoolFBP(pool).add_liquidity(deposits_pp, 0);

            } else if (PP_TOKENS.length == 3) {
                uint256[3] memory deposits_pp;

                for (uint8 i = 0; i < PP_TOKENS.length; i++) {
                    deposits_pp[i] = IERC20(PP_TOKENS[i]).balanceOf(address(this));
                    if (IERC20(PP_TOKENS[i]).balanceOf(address(this)) > 0) {
                        IERC20(PP_TOKENS[i]).safeApprove(pool, IERC20(PP_TOKENS[i]).balanceOf(address(this)));
                    }

                } 

                ICRVPlainPoolFBP(pool).add_liquidity(deposits_pp, 0);

            } else if (PP_TOKENS.length == 4) {
                uint256[4] memory deposits_pp;

                for (uint8 i = 0; i < PP_TOKENS.length; i++) {
                    deposits_pp[i] = IERC20(PP_TOKENS[i]).balanceOf(address(this));
                    if (IERC20(PP_TOKENS[i]).balanceOf(address(this)) > 0) {
                        IERC20(PP_TOKENS[i]).safeApprove(pool, IERC20(PP_TOKENS[i]).balanceOf(address(this)));
                    }

                } 

                ICRVPlainPoolFBP(pool).add_liquidity(deposits_pp, 0);         

                }

        }

        stakeLP();

        //increase baseline
        uint256 postBaseline = USD_Convertible();
        require(postBaseline > preBaseline, "OCY_ANGLE::pushToLockerMulti() postBaseline < preBaseline");

        baseline = postBaseline;
    }
    
    /// @dev    This will stake total balance of LP tokens on Convex
    /// @notice Private function, should only be called through invest().
    function stakeLP() private {
        IERC20(POOL_LP_TOKEN).safeApprove(CVX_Deposit_Address, IERC20(POOL_LP_TOKEN).balanceOf(address(this)));
        ICVX_Booster(CVX_Deposit_Address).depositAll(convexPoolID, true);
    }

    ///@dev returns the value of our LP position in USD.
    function USD_Convertible() public view returns (uint256 _amount) {
        uint256 contractLP = IConvexRewards(CVX_Reward_Address).balanceOf(address(this));

        if (metaOrPlainPool == true) {

            uint256 amountBASE_TOKEN = ICRVMetaPool(pool).calc_withdraw_one_coin(contractLP, indexBASE_TOKEN);
            (,int price,,,) = AggregatorV3Interface(chainlinkPriceFeeds[0]).latestRoundData();
            require(price >= 0);
            _amount = (uint256(price) * amountBASE_TOKEN) / (10** AggregatorV3Interface(chainlinkPriceFeeds[0]).decimals());


        }

        if (metaOrPlainPool == false) {

            // Query the latest price from each feed and take the minimum price.
            int256[] memory prices = new int256[](PP_TOKENS.length);

            for (uint8 i = 0; i < PP_TOKENS.length; i++) {
                (, prices[i],,,) = AggregatorV3Interface(chainlinkPriceFeeds[i]).latestRoundData();
            }

            int256 minPrice = prices[0];
            uint128 index = 0;

            for (uint128 i = 1; i < prices.length; i++) {
                if (prices[i] < minPrice) {
                    minPrice = prices[i];
                    index = i;
                }
            }

            require(minPrice >= 0);

            uint256 amountOfPP_TOKEN = ICRVPlainPoolFBP(pool).calc_withdraw_one_coin(contractLP, int128(index));

            _amount = (uint256(minPrice) * amountOfPP_TOKEN) / (10**AggregatorV3Interface(chainlinkPriceFeeds[uint128(index)]).decimals());

        }
        

    }

    ///@dev public accessible function to harvest yield every 30 days. Yield will have to be transferred to YDL by a keeper via forwardYieldKeeper()
    ///TODO: implement treshold for baseline above which we decide to sell LP tokens as yield ?
    function harvestYield() public {
        require(block.timestamp > nextYieldDistribution);
        nextYieldDistribution = block.timestamp + 30 days;

        //We check initial balances of tokens in order to avoid confusion between tokens that could be pushed through "pushToLockerMulti" at approx same time and not converted yet while we are harvesting. Can optimize by including CRV and CVX to the "rewardsAddresses[]".
        uint256 initCRVBalance = IERC20(CRV).balanceOf(address(this));
        uint256 initCVXBalance = IERC20(CVX).balanceOf(address(this));
        uint256[] memory initPoolTokensBalance;
        uint256[] memory initRewardsBalance;

        if (metaOrPlainPool == true) {
            uint256[] memory _initPoolTokensBalance = new uint256[](1);
            _initPoolTokensBalance[0] = IERC20(BASE_TOKEN).balanceOf(address(this));
            initPoolTokensBalance = _initPoolTokensBalance;
        }

        if (metaOrPlainPool == false) {
            uint256[] memory _initPoolTokensBalance = new uint256[](PP_TOKENS.length);
            for (uint8 i = 0; i < PP_TOKENS.length; i++) {
                _initPoolTokensBalance[i] = IERC20(PP_TOKENS[i]).balanceOf(address(this));
            }
            initPoolTokensBalance = _initPoolTokensBalance;
        }

        if (extraRewards == true) {
            uint256[] memory _initRewardsBalance = new uint256[](rewardsAddresses.length);
            for (uint8 i = 0; i < rewardsAddresses.length; i++) {
                _initRewardsBalance[i] = IERC20(rewardsAddresses[i]).balanceOf(address(this));
            }
            initRewardsBalance = _initRewardsBalance;
        }

        //Claiming rewards on Convex
        IConvexRewards(CVX_Reward_Address).getReward();

        //Calculate the rewards to transfer to YDL.
        toForwardCRV = IERC20(CRV).balanceOf(address(this)) - initCRVBalance;
        toForwardCVX = IERC20(CVX).balanceOf(address(this)) - initCVXBalance;

        //If extra rewards, first check if reward = distributedAsset. In case these are the same, transfer the rewards directly to the YDL.
        if (extraRewards == true) {
            uint256[] memory toForwardExtra = new uint256[](rewardsAddresses.length);

            for (uint8 i = 0; i < rewardsAddresses.length; i++) {
                if (rewardsAddresses[i] == IZivoeYDL_P_3(IZivoeGlobals_P_4(GBL).YDL()).distributedAsset()) {
                    IERC20(rewardsAddresses[i]).safeTransfer(IZivoeGlobals_P_4(GBL).YDL(), IERC20(rewardsAddresses[i]).balanceOf(address(this)) - initRewardsBalance[i]);
                } else {
                    toForwardExtra[i] = IERC20(rewardsAddresses[i]).balanceOf(address(this)) - initRewardsBalance[i];
                }
            }

            toForwardExtraRewards = toForwardExtra;
        }

        //Calculate the amount from the baseline that should be transfered.
        uint256 updatedBaseline = USD_Convertible();

        if ((updatedBaseline + yieldOwedToYDL) > baseline) {
            uint256 yieldFromLP = updatedBaseline - baseline + yieldOwedToYDL;

            //determine lpPrice TODO: check if decimals conversion ok.
            uint256 lpPrice = lpPriceInUSD() / 10**9;
            uint256 amountOfLPToSell = (yieldFromLP * 10**9) / lpPrice;

            IConvexRewards(CVX_Reward_Address).withdrawAndUnwrap(amountOfLPToSell, false);
            
            if (metaOrPlainPool == true) {
                uint256[] memory tokensToTransferBaseline = new uint256[](1);
                ICRVMetaPool(pool).remove_liquidity_one_coin(IERC20(POOL_LP_TOKEN).balanceOf(address(this)), indexBASE_TOKEN, 0);
                // if BASE_TOKEN = YDL distributed asset, transfer yield directly to YDL. Otherwise account for yield to convert by ZVL.
                if (BASE_TOKEN == IZivoeYDL_P_3(IZivoeGlobals_P_4(GBL).YDL()).distributedAsset()) {
                    IERC20(BASE_TOKEN).safeTransfer(IZivoeGlobals_P_4(GBL).YDL(), IERC20(BASE_TOKEN).balanceOf(address(this)) - initPoolTokensBalance[0]);
                } else {
                    tokensToTransferBaseline[0] = IERC20(BASE_TOKEN).balanceOf(address(this)) - initPoolTokensBalance[0];
                    toForwardTokensBaseline = tokensToTransferBaseline;
                }
            }

            if (metaOrPlainPool == false) {
                uint256[] memory tokensToTransferBaseline = new uint256[](PP_TOKENS.length);
                removeLiquidityPlainPool(false);
                // if pool token = YDL distributed asset, transfer yield directly to YDL. Otherwise account for yield to convert by ZVL.
                for (uint8 i = 0; i < PP_TOKENS.length; i++) {
                    if (PP_TOKENS[i] == IZivoeYDL_P_3(IZivoeGlobals_P_4(GBL).YDL()).distributedAsset()) {
                        IERC20(PP_TOKENS[i]).safeTransfer(IZivoeGlobals_P_4(GBL).YDL(), IERC20(PP_TOKENS[i]).balanceOf(address(this)) - initPoolTokensBalance[i]);
                    } else {
                        tokensToTransferBaseline[i] = IERC20(PP_TOKENS[i]).balanceOf(address(this)) - initPoolTokensBalance[i];
                    }
                }
                toForwardTokensBaseline = tokensToTransferBaseline;
            }
        }

    }

    /// @dev This function converts and forwards rewards to the YDL.
    /// TODO: check if optimal to call for each asset separately. Will have to check to transfer the rewards that equal to the distributedAsset() (separate public fct ?) + set accounting for rewards to 0.
    function forwardYieldKeeperCRV_CVX(address asset, bytes calldata data) external {
        require(IZivoeGlobals_P_4(GBL).isKeeper(_msgSender()), "e_OCY_CVX_Modular::forwardYieldKeeper() !IZivoeGlobals_P_4(GBL).isKeeper(_msgSender())");
    
        address _toAsset = IZivoeYDL_P_3(IZivoeGlobals_P_4(GBL).YDL()).distributedAsset();
        uint256 amountForConversion;

        if (asset == CRV) {
            amountForConversion = toForwardCRV;
        } else if (asset == CVX) {
            amountForConversion = toForwardCVX;
        }

        // Swap available "amountForConversion" from reward token to YDL.distributedAsset().
        convertAsset(asset, _toAsset, amountForConversion, data);

        // Transfer all _toAsset received to the YDL, then reduce amountForConversion to 0.
        IERC20(_toAsset).safeTransfer(IZivoeGlobals_P_4(GBL).YDL(), IERC20(_toAsset).balanceOf(address(this)));
        
        //reset amounts to 0 (amounts to transfer)
        if (asset == CRV) {
            toForwardCRV = 0;
        } else if (asset == CVX) {
            toForwardCVX = 0;
        }        

    }

    function lpPriceInUSD() public view returns (uint256 price) {
        //TODO: everywhere in contract take into account the decimals of the token for which we calculate the price.
        if (metaOrPlainPool == true) {
            //pool token balances
            uint256 baseTokenBalance = IERC20(BASE_TOKEN).balanceOf(pool);
            uint256 standardizedBaseTokenBalance = IZivoeGlobals_P_4(GBL).standardize(baseTokenBalance, BASE_TOKEN);
            uint256 underlyingLPTokenBalance = IERC20(MP_UNDERLYING_LP_TOKEN).balanceOf(pool);

            //price of base token
            (,int baseTokenPrice,,,) = AggregatorV3Interface(chainlinkPriceFeeds[0]).latestRoundData();
            require(baseTokenPrice >= 0);

            //base token total value
            uint256 baseTokenTotalValue = (standardizedBaseTokenBalance * uint256(baseTokenPrice)) / (10** AggregatorV3Interface(chainlinkPriceFeeds[0]).decimals());

            //underlying LP token price
            uint256 totalValueOfUnderlyingPool;

            for (uint8 i = 0; i < numberOfTokensUnderlyingLPPool; i++) {
                address underlyingToken = ICRVMetaPool(MP_UNDERLYING_LP_POOL).coins(i);
                uint256 underlyingTokenAmount = ICRVMetaPool(MP_UNDERLYING_LP_POOL).balances(i);
                (,int underlyingTokenPrice,,,) = AggregatorV3Interface(chainlinkPriceFeeds[i+1]).latestRoundData();
                require(underlyingTokenPrice >= 0);

                uint256 standardizedAmount = IZivoeGlobals_P_4(GBL).standardize(underlyingTokenAmount, underlyingToken);
                totalValueOfUnderlyingPool += (standardizedAmount * uint256(underlyingTokenPrice)) / (10** AggregatorV3Interface(chainlinkPriceFeeds[i+1]).decimals());
            }

            uint256 underlyingLPTokenPrice = (totalValueOfUnderlyingPool * 10**9) / (IERC20(MP_UNDERLYING_LP_TOKEN).totalSupply() / 10**9);

            //pool total value
            uint256 poolTotalValue = baseTokenTotalValue + ((underlyingLPTokenPrice/10**9) * (underlyingLPTokenBalance/10**9));
            
            //MP LP Token Price
            uint256 MP_lpTokenPice = (poolTotalValue * 10**9) / (IERC20(POOL_LP_TOKEN).totalSupply()/ 10**9);

            return MP_lpTokenPice;

        }

        if (metaOrPlainPool == false) {
           
            uint256 totalValueInPool;

            for (uint8 i = 0; i < PP_TOKENS.length; i++) {
                address token = PP_TOKENS[i];
                uint256 tokenAmount = ICRVPlainPoolFBP(pool).balances(i);
                (,int tokenPrice,,,) = AggregatorV3Interface(chainlinkPriceFeeds[i]).latestRoundData();
                require(tokenPrice >= 0);

                uint256 standardizedAmount = IZivoeGlobals_P_4(GBL).standardize(tokenAmount, token);
                totalValueInPool += (standardizedAmount * uint256(tokenPrice)) / (10** AggregatorV3Interface(chainlinkPriceFeeds[i]).decimals());
            }

            //PP LP Token Price
            uint256 PP_lpTokenPrice = (totalValueInPool * 10**9) / (IERC20(POOL_LP_TOKEN).totalSupply()/10**9);

            return PP_lpTokenPrice;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../../ZivoeLocker.sol";
import "../../Utility/ZivoeSwapper.sol";

import {
    ICRVPlainPoolFBP, 
    IZivoeGlobals, 
    ICRVMetaPool, 
    ICVX_Booster, 
    IConvexRewards, 
    IZivoeYDL, 
    AggregatorV3Interface
} from "../../../misc/InterfacesAggregated.sol";

interface IZivoeGlobals_P_4 {
    function YDL() external view returns (address);
    function isKeeper(address) external view returns (bool);
    function standardize(uint256, address) external view returns (uint256);
}

interface IZivoeYDL_P_3 {
    function distributedAsset() external view returns (address);
}

/// @dev    This contract aims at deploying lockers that will invest in Convex pools. 
///         Plain pools should contain only stablecoins denominated in same currency (all tokens in USD or all tokens in EUR for example, otherwise USD_Convertible won't be correct).

contract OCY_CVX_Modular is ZivoeLocker, ZivoeSwapper {
    
    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    address public immutable GBL; /// @dev The ZivoeGlobals contract.
    uint256 public nextYieldDistribution;     /// @dev Determines next available forwardYield() call. 
    uint256 public investTimeLock; /// @dev defines a period for keepers to invest before public accessible function.
    bool public metaOrPlainPool;  /// @dev If true = metapool, if false = plain pool.
    bool public extraRewards;     /// @dev If true, extra rewards are distributed on top of CRV and CVX. If false, no extra rewards.
    uint256 public baseline;      /// @dev USD convertible, used for forwardYield() accounting.
    uint256 public yieldOwedToYDL; /// @dev Part of LP token increase over baseline that is owed to the YDL (needed for accounting when pulling or investing capital).
    uint256 public toForwardCRV; /// @dev CRV tokens harvested that need to be transfered by ZVL to the YDL.
    uint256 public toForwardCVX; /// @dev CVX tokens harvested that need to be transfered by ZVL to the YDL.
    uint256[] public toForwardExtraRewards; /// @dev Extra rewards harvested that need to be transfered by ZVL to the YDL.
    uint256[] public toForwardTokensBaseline; /// @dev LP tokens harvested that need to be transfered by ZVL to the YDL.


    /// @dev Convex addresses.
    address public CVX_Deposit_Address;
    address public CVX_Reward_Address;

    /// @dev Convex staking pool ID.
    uint256 public convexPoolID;

    /// @dev Reward addresses.
    ///TODO: could optimize with including CVX and CRV in "rewardsAddresses", to check.
    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address[] public rewardsAddresses;

    /// @dev Curve addresses:
    address public pool;
    address public POOL_LP_TOKEN;

    // NOTE: Not able to find a method to determine which of both coins(0,1) is the BASE_TOKEN, thus has to be specified in constructor.
    /// @dev Metapool parameters:
    address public BASE_TOKEN;
    address public MP_UNDERLYING_LP_TOKEN;
    address public MP_UNDERLYING_LP_POOL;

    // NOTE: Needed to calculate the LP price of the underlying LP Token.
    uint8 public numberOfTokensUnderlyingLPPool;
    int128 public indexBASE_TOKEN;

    /// @dev Plain Pool parameters:
    address[] public PP_TOKENS; 

    /// @dev chainlink price feeds:
    address[] public chainlinkPriceFeeds;

    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the e_OCY_CVX_Modular.sol contract.
    /// @param _ZivoeAddresses _ZivoeAddresses[0] = The administrator of this contract (intended to be ZivoeDAO) and _ZivoeAddresses[1] = GBL (the ZivoeGlobals contract).
    /// @param _boolMetaOrPlainAndRewards _boolMetaOrPlainAndRewards[0] => If true: metapool, if false: plain pool. _boolMetaOrPlainAndRewards[1] => if true: extra rewards distributed on top of CRV or CVX.
    /// @param _curvePool address of the Curve Pool.
    /// @param _CVX_Deposit_Address address of the convex Booster contract.
    /// @param _rewardsAddresses addresses of the extra rewards. If _extraRewards = false set as an array of the zero address.
    /// @param _BASE_TOKEN_MP if metapool should specify the address of the base token of the pool. If plain pool, set to the zero address.
    /// @param _MP_UNDERLYING_LP_POOL if metapool specify address of the underlying LP token's pool (3CRV for example).
    /// @param _numberOfTokensUnderlyingLPPool if metapool: specify the number of tokens in the underlying LP pool (for 3CRV pool set to 3). If plain pool: set to 0.
    /// @param _numberOfTokensPP If pool is a metapool, set to 0. If plain pool, specify the number of coins in the pool.
    /// @param _convexPoolID Indicate the ID of the Convex pool where the LP token should be staked.
    /// @param _chainlinkPriceFeeds array containing the addresses of the chainlink price feeds, should be provided in correct order (refer to coins index in Curve pool)

    constructor(
        address[] memory _ZivoeAddresses,  
        bool[] memory _boolMetaOrPlainAndRewards, 
        address _curvePool, 
        address _CVX_Deposit_Address, 
        address[] memory _rewardsAddresses, 
        address _BASE_TOKEN_MP, 
        address _MP_UNDERLYING_LP_POOL,
        uint8 _numberOfTokensUnderlyingLPPool,
        uint8 _numberOfTokensPP, 
        uint256 _convexPoolID,
        address[] memory _chainlinkPriceFeeds) {

        require(_numberOfTokensPP < 5, "e_OCY_CVX_Modular::constructor() max 4 tokens in plain pool");
        require(_rewardsAddresses.length < 5, "e_OCY_CVX_Modular::constructor() max 4 reward tokens");
        require(_numberOfTokensUnderlyingLPPool < 5, "e_OCY_CVX_Modular::constructor() max 4 tokens in underlying LP pool");

        transferOwnership(_ZivoeAddresses[0]);
        GBL = _ZivoeAddresses[1];
        CVX_Deposit_Address = _CVX_Deposit_Address;
        CVX_Reward_Address = ICVX_Booster(_CVX_Deposit_Address).poolInfo(_convexPoolID).crvRewards;
        metaOrPlainPool = _boolMetaOrPlainAndRewards[0];
        convexPoolID = _convexPoolID;
        extraRewards = _boolMetaOrPlainAndRewards[1];
        numberOfTokensUnderlyingLPPool = _numberOfTokensUnderlyingLPPool;


        // Initializes rewards (other than CVX and CRV).
        if (extraRewards == true) {
            for (uint8 i = 0; i < _rewardsAddresses.length; i++) {
                rewardsAddresses.push(_rewardsAddresses[i]);
            }
        }    

        if (metaOrPlainPool == true) {
            require(_chainlinkPriceFeeds.length == (1 + numberOfTokensUnderlyingLPPool) , "e_OCY_CVX_Modular::constructor() no correct amount of price feeds for metapool");
            pool = _curvePool;
            POOL_LP_TOKEN = ICVX_Booster(_CVX_Deposit_Address).poolInfo(_convexPoolID).lptoken;
            BASE_TOKEN = _BASE_TOKEN_MP;
            MP_UNDERLYING_LP_POOL = _MP_UNDERLYING_LP_POOL;
        
            for (uint8 i = 0; i < _chainlinkPriceFeeds.length; i++) {
                chainlinkPriceFeeds.push(_chainlinkPriceFeeds[i]);
            }
            if (ICRVMetaPool(pool).coins(0) == _BASE_TOKEN_MP) {
                MP_UNDERLYING_LP_TOKEN = ICRVMetaPool(pool).coins(1);
                indexBASE_TOKEN = 0;
            } else if (ICRVMetaPool(pool).coins(1) == _BASE_TOKEN_MP) {
                MP_UNDERLYING_LP_TOKEN = ICRVMetaPool(pool).coins(0);
                indexBASE_TOKEN = 1;
            }

        }

        if (metaOrPlainPool == false) {
            require(_chainlinkPriceFeeds.length == _numberOfTokensPP, "e_OCY_CVX_Modular::constructor() plain pool: number of price feeds should correspond to number of tokens");
            pool = _curvePool;
            POOL_LP_TOKEN = ICVX_Booster(_CVX_Deposit_Address).poolInfo(_convexPoolID).lptoken;

            // Initializes tokens of the plain pool and sets chainlink price feeds.
            /// TODO: Check if possible to require that price feeds submitted in right order.
            for (uint8 i = 0; i < _numberOfTokensPP; i++) {
                PP_TOKENS.push(ICRVPlainPoolFBP(pool).coins(i));
                chainlinkPriceFeeds.push(_chainlinkPriceFeeds[i]);
            }
        }
    }

    // ---------------
    //    Functions
    // ---------------

    function canPushMulti() public pure override returns (bool) {
        return true;
    }

    function canPullMulti() public pure override returns (bool) {
        return true;
    }

    function canPullPartial() public override pure returns (bool) {
        return true;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV3Pool_ZivoeSwapper {
    /// @notice Will return the address of the token at index 0.
    /// @return token0 The address of the token at index 0.
    function token0() external view returns (address token0);

    /// @notice Will return the address of the token at index 1.
    /// @return token1 The address of the token at index 1.
    function token1() external view returns (address token1);
}

interface IUniswapV2Pool_ZivoeSwapper {
    /// @notice Will return the address of the token at index 0.
    /// @return token0 The address of the token at index 0.
    function token0() external view returns (address);

    /// @notice Will return the address of the token at index 1.
    /// @return token1 The address of the token at index 1.
    function token1() external view returns (address);
}



/// @notice OneInchPrototype contract integrates with 1INCH to support custom data input.
contract ZivoeSwapper {

    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    address public immutable router1INCH_V4 = 0x1111111254fb6c44bAC0beD2854e76F90643097d;  /// @dev The 1INCH v4 Router.

    uint256 private constant _ONE_FOR_ZERO_MASK = 1 << 255;
    uint256 private constant _REVERSE_MASK =   0x8000000000000000000000000000000000000000000000000000000000000000;

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    struct OrderRFQ {
        // Lowest 64 bits is the order id, next 64 bits is the expiration timestamp.
        // Highest bit is unwrap WETH flag which is set on taker's side.
        // [unwrap eth(1 bit) | unused (127 bits) | expiration timestamp(64 bits) | orderId (64 bits)]
        uint256 info;
        IERC20 makerAsset;
        IERC20 takerAsset;
        address maker;
        address allowedSender;  // Equals address(0) on public orders.
        uint256 makingAmount;
        uint256 takingAmount;
    }



    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeSwapper.sol contract.
    constructor() { }



    // ---------------
    //    Functions
    // ---------------

    /// @notice Will validate the data retrieved from 1inch API triggering a swap() function in 1inch router.
    /// @dev    The swap() function will execute a swap through multiple sources.
    /// @dev    "7c025200": "swap(address,(address,address,address,address,uint256,uint256,uint256,bytes),bytes)"
    function handle_validation_7c025200(bytes calldata data, address assetIn, address assetOut, uint256 amountIn) internal view {
        (, SwapDescription memory _b,) = abi.decode(data[4:], (address, SwapDescription, bytes));
        require(address(_b.srcToken) == assetIn, "ZivoeSwapper::handle_validation_7c025200() address(_b.srcToken) != assetIn");
        require(address(_b.dstToken) == assetOut, "ZivoeSwapper::handle_validation_7c025200() address(_b.dstToken) != assetOut");
        require(_b.amount == amountIn, "ZivoeSwapper::handle_validation_7c025200() _b.amount != amountIn");
        require(_b.dstReceiver == address(this), "ZivoeSwapper::handle_validation_7c025200() _b.dstReceiver != address(this)");
    }

    /// @notice Will validate the data retrieved from 1inch API triggering an uniswapV3Swap() function in 1inch router.
    /// @dev The uniswapV3Swap() function will execute a swap through Uniswap V3 pools.
    /// @dev "e449022e": "uniswapV3Swap(uint256,uint256,uint256[])"
    function handle_validation_e449022e(bytes calldata data, address assetIn, address assetOut, uint256 amountIn) internal view {
        (uint256 _a,, uint256[] memory _c) = abi.decode(data[4:], (uint256, uint256, uint256[]));
        require(_a == amountIn, "ZivoeSwapper::handle_validation_e449022e() _a != amountIn");
        bool zeroForOne_0 = _c[0] & _ONE_FOR_ZERO_MASK == 0;
        bool zeroForOne_CLENGTH = _c[_c.length - 1] & _ONE_FOR_ZERO_MASK == 0;
        if (zeroForOne_0) {
            require(IUniswapV3Pool_ZivoeSwapper(address(uint160(uint256(_c[0])))).token0() == assetIn,
            "ZivoeSwapper::handle_validation_e449022e() IUniswapV3Pool_ZivoeSwapper(address(uint160(uint256(_c[0])))).token0() != assetIn");
        }
        else {
            require(IUniswapV3Pool_ZivoeSwapper(address(uint160(uint256(_c[0])))).token1() == assetIn,
            "ZivoeSwapper::handle_validation_e449022e() IUniswapV3Pool_ZivoeSwapper(address(uint160(uint256(_c[0])))).token1() != assetIn");
        }
        if (zeroForOne_CLENGTH) {
            require(IUniswapV3Pool_ZivoeSwapper(address(uint160(uint256(_c[_c.length - 1])))).token1() == assetOut,
            "ZivoeSwapper::handle_validation_e449022e() IUniswapV3Pool_ZivoeSwapper(address(uint160(uint256(_c[_c.length - 1])))).token1() != assetOut");
        }
        else {
            require(IUniswapV3Pool_ZivoeSwapper(address(uint160(uint256(_c[_c.length - 1])))).token0() == assetOut,
            "ZivoeSwapper::handle_validation_e449022e() IUniswapV3Pool_ZivoeSwapper(address(uint160(uint256(_c[_c.length - 1])))).token0() != assetOut");
        }
    }

    /// @notice Will validate the data retrieved from 1inch API triggering an unoswap() function in 1inch router.
    /// @dev The unoswap() function will execute a swap through Uniswap V2 pools or similar.
    /// @dev "2e95b6c8": "unoswap(address,uint256,uint256,bytes32[])"
    function handle_validation_2e95b6c8(bytes calldata data, address assetIn, address assetOut, uint256 amountIn) internal view {
        (address _a, uint256 _b,, bytes32[] memory _d) = abi.decode(data[4:], (address, uint256, uint256, bytes32[]));
        require(_a == assetIn, "ZivoeSwapper::handle_validation_2e95b6c8() _a != assetIn");
        require(_b == amountIn, "ZivoeSwapper::handle_validation_2e95b6c8() _b != amountIn");
        bool zeroForOne_0;
        bool zeroForOne_DLENGTH;
        bytes32 info_0 = _d[0];
        bytes32 info_DLENGTH = _d[_d.length - 1];
        assembly {
            zeroForOne_0 := and(info_0, _REVERSE_MASK)
            zeroForOne_DLENGTH := and(info_DLENGTH, _REVERSE_MASK)
        }
        if (zeroForOne_0) {
            require(IUniswapV2Pool_ZivoeSwapper(address(uint160(uint256(_d[0])))).token1() == assetIn,
            "ZivoeSwapper::handle_validation_2e95b6c8() IUniswapV2Pool_ZivoeSwapper(address(uint160(uint256(_d[0])))).token1() != assetIn");
        }
        else {
            require(IUniswapV2Pool_ZivoeSwapper(address(uint160(uint256(_d[0])))).token0() == assetIn,
            "ZivoeSwapper::handle_validation_2e95b6c8() IUniswapV2Pool_ZivoeSwapper(address(uint160(uint256(_d[0])))).token0() != assetIn");
        }
        if (zeroForOne_DLENGTH) {
            require(IUniswapV2Pool_ZivoeSwapper(address(uint160(uint256(_d[_d.length - 1])))).token0() == assetOut,
            "ZivoeSwapper::handle_validation_2e95b6c8() IUniswapV2Pool_ZivoeSwapper(address(uint160(uint256(_d[_d.length - 1])))).token0() != assetOut");
        }
        else {
            require(IUniswapV2Pool_ZivoeSwapper(address(uint160(uint256(_d[_d.length - 1])))).token1() == assetOut,
            "ZivoeSwapper::handle_validation_2e95b6c8() IUniswapV2Pool_ZivoeSwapper(address(uint160(uint256(_d[_d.length - 1])))).token1() != assetOut");
        }
    }

    /// @notice Will validate the data retrieved from 1inch API triggering a fillOrderRFQ() function in 1inch router.
    /// @dev The fillOrderRFQ() function will execute a swap through limit orders.
    /// @dev "d0a3b665": "fillOrderRFQ((uint256,address,address,address,address,uint256,uint256),bytes,uint256,uint256)"
    function handle_validation_d0a3b665(bytes calldata data, address assetIn, address assetOut, uint256 amountIn) internal pure {
        (OrderRFQ memory _a,,,) = abi.decode(data[4:], (OrderRFQ, bytes, uint256, uint256));
        require(address(_a.takerAsset) == assetIn, "ZivoeSwapper::handle_validation_d0a3b665() address(_a.takerAsset) != assetIn");
        require(address(_a.makerAsset) == assetOut, "ZivoeSwapper::handle_validation_d0a3b665() address(_a.makerAsset) != assetOut");
        require(_a.takingAmount == amountIn, "ZivoeSwapper::handle_validation_d0a3b665() _a.takingAmount != amountIn");
    }

    function convertAsset(
        address assetIn,
        address assetOut,
        uint256 amountIn,
        bytes calldata data
    ) internal {
        // Handle validation.
        bytes4 sig = bytes4(data[:4]);
        if (sig == bytes4(keccak256("swap(address,(address,address,address,address,uint256,uint256,uint256,bytes),bytes)"))) {
            handle_validation_7c025200(data, assetIn, assetOut, amountIn);
        }
        else if (sig == bytes4(keccak256("uniswapV3Swap(uint256,uint256,uint256[])"))) {
            handle_validation_e449022e(data, assetIn, assetOut, amountIn);
        }
        else if (sig == bytes4(keccak256("unoswap(address,uint256,uint256,bytes32[])"))) {
            handle_validation_2e95b6c8(data, assetIn, assetOut, amountIn);
        }
        else if (sig == bytes4(keccak256("fillOrderRFQ((uint256,address,address,address,address,uint256,uint256),bytes,uint256,uint256)"))) {
            handle_validation_d0a3b665(data, assetIn, assetOut, amountIn);
        }
        else {
            revert();
        }

        // Execute swap.
        (bool succ,) = address(router1INCH_V4).call(data);
        require(succ, "ZivoeSwapper::convertAsset() !succ");
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

/// @notice    BaseContractTemplate.sol is intended to be a template for new .sol files.
contract BaseContractTemplate {
    
    // ---------------------
    //    State Variables
    // ---------------------

    // -----------------
    //    Constructor
    // -----------------

    constructor() { }

    // ------------
    //    Events
    // ------------

    // ---------------
    //    Modifiers
    // ---------------

    // ---------------
    //    Functions
    // ---------------

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// ----------
//    EIPs
// ----------

interface IERC20Mintable is IERC20, IERC20Metadata {
    function mint(address account, uint256 amount) external;
    function isMinter(address account) external view returns (bool);
}

// interface IERC721 {
//     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
//     function approve(address to, uint256 tokenId) external;
// }

// interface IERC1155 { 
//     function setApprovalForAll(address operator, bool approved) external;
//     function safeBatchTransferFrom(
//         address from,
//         address to,
//         uint256[] calldata ids,
//         uint256[] calldata amounts,
//         bytes calldata data
//     ) external;
// }




// -----------
//    Zivoe
// -----------

interface GenericData {
    function GBL() external returns (address);
    function owner() external returns (address);
}

interface ILocker {
    function pushToLocker(address asset, uint256 amount) external;
    function pullFromLocker(address asset) external;
    function pullFromLockerPartial(address asset, uint256 amount) external;
    function pushToLockerMulti(address[] calldata assets, uint256[] calldata amounts) external;
    function pullFromLockerMulti(address[] calldata assets) external;
    function pullFromLockerMultiPartial(address[] calldata assets, uint256[] calldata amounts) external;
    function pushToLockerERC721(address asset, uint256 tokenId, bytes calldata data) external;
    function pullFromLockerERC721(address asset, uint256 tokenId, bytes calldata data) external;
    function pushToLockerMultiERC721(address[] calldata assets, uint256[] calldata tokenIds, bytes[] calldata data) external;
    function pullFromLockerMultiERC721(address[] calldata assets, uint256[] calldata tokenIds, bytes[] calldata data) external;
    function pushToLockerERC1155(
        address asset, 
        uint256[] calldata ids, 
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
    function pullFromLockerERC1155(
        address asset, 
        uint256[] calldata ids, 
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
    function canPush() external view returns (bool);
    function canPull() external view returns (bool);
    function canPullPartial() external view returns (bool);
    function canPushMulti() external view returns (bool);
    function canPullMulti() external view returns (bool);
    function canPullMultiPartial() external view returns (bool);
    function canPushERC721() external view returns (bool);
    function canPullERC721() external view returns (bool);
    function canPushMultiERC721() external view returns (bool);
    function canPullMultiERC721() external view returns (bool);
    function canPushERC1155() external view returns (bool);
    function canPullERC1155() external view returns (bool);
}

interface IZivoeDAO is GenericData {
    
}

interface IZivoeGovernor {
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function quorum(uint256 blockNumber) external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function name() external view returns (string memory);
    function version() external view returns (string memory);
    function COUNTING_MODE() external pure returns (string memory);
    function quorumNumerator() external view returns (uint256);
    function quorumDenominator() external view returns (uint256);
    function timelock() external view returns (address);
    function token() external view returns (address); // IVotes?
}

interface IZivoeGlobals {
    function DAO() external view returns (address);
    function ITO() external view returns (address);
    function stJTT() external view returns (address);
    function stSTT() external view returns (address);
    function stZVE() external view returns (address);
    function vestZVE() external view returns (address);
    function YDL() external view returns (address);
    function zJTT() external view returns (address);
    function zSTT() external view returns (address);
    function ZVE() external view returns (address);
    function ZVL() external view returns (address);
    function ZVT() external view returns (address);
    function GOV() external view returns (address);
    function TLC() external view returns (address);
    function isKeeper(address) external view returns (bool);
    function isLocker(address) external view returns (bool);
    function stablecoinWhitelist(address) external view returns (bool);
    function defaults() external view returns (uint256);
    function maxTrancheRatioBIPS() external view returns (uint256);
    function minZVEPerJTTMint() external view returns (uint256);
    function maxZVEPerJTTMint() external view returns (uint256);
    function lowerRatioIncentive() external view returns (uint256);
    function upperRatioIncentive() external view returns (uint256);
    function increaseDefaults(uint256) external;
    function decreaseDefaults(uint256) external;
    function standardize(uint256, address) external view returns (uint256);
    function adjustedSupplies() external view returns (uint256, uint256);
}

interface IZivoeITO is GenericData {
    function claim() external returns (uint256 _zJTT, uint256 _zSTT, uint256 _ZVE);
    function start() external view returns (uint256);
    function end() external view returns (uint256);
    function stablecoinWhitelist(address) external view returns (bool);
}

interface ITimelockController is GenericData {
    function getMinDelay() external view returns (uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function getRoleAdmin(bytes32) external view returns (bytes32);
}

struct Reward {
    uint256 rewardsDuration;        /// @dev How long rewards take to vest, e.g. 30 days.
    uint256 periodFinish;           /// @dev When current rewards will finish vesting.
    uint256 rewardRate;             /// @dev Rewards emitted per second.
    uint256 lastUpdateTime;         /// @dev Last time this data struct was updated.
    uint256 rewardPerTokenStored;   /// @dev Last snapshot of rewardPerToken taken.
}

interface IZivoeRewards is GenericData {
    function depositReward(address _rewardsToken, uint256 reward) external;
    function rewardTokens() external view returns (address[] memory);
    function rewardData(address) external view returns (Reward memory);
    function stakingToken() external view returns (address);
    function viewRewards(address, address) external view returns (uint256);
    function viewAccountRewardPerTokenPaid(address, address) external view returns (uint256);
}

interface IZivoeRewardsVesting is GenericData, IZivoeRewards {

}

interface IZivoeToken is IERC20, IERC20Metadata, GenericData {

}

interface IZivoeTranches is ILocker, GenericData {
    function unlock() external;
    function tranchesUnlocked() external view returns (bool);
    function GBL() external view returns (address);
}
interface IZivoeTrancheToken is IERC20, IERC20Metadata, GenericData, IERC20Mintable {

}

interface IZivoeYDL is GenericData {
    function distributeYield() external;
    function supplementYield(uint256 amount) external;
    function unlock() external;
    function unlocked() external view returns (bool);
    function distributedAsset() external view returns (address);
    function emaSTT() external view returns (uint256);
    function emaJTT() external view returns (uint256);
    function emaYield() external view returns (uint256);
    function numDistributions() external view returns (uint256);
    function lastDistribution() external view returns (uint256);
    function targetAPYBIPS() external view returns (uint256);
    function targetRatioBIPS() external view returns (uint256);
    function protocolEarningsRateBIPS() external view returns (uint256);
    function daysBetweenDistributions() external view returns (uint256);
    function retrospectiveDistributions() external view returns (uint256);
    function earningsTrancheuse(uint256, uint256) external view returns (uint256[] memory, uint256, uint256, uint256[] memory);
}


// ---------------
//    Protocols
// ---------------

struct PoolInfo {
    address lptoken;
    address token;
    address gauge;
    address crvRewards;
    address stash;
    bool shutdown;
}

struct TokenInfo {
    address token;
    address rewardAddress;
    uint256 lastActiveTime;
}

interface ICVX_Booster {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);
    function depositAll(uint256 _pid, bool _stake) external returns(bool);
    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
}

interface IConvexRewards {
    function getReward() external returns (bool);
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns (bool);
    function withdrawAllAndUnwrap(bool _claim) external;
    function balanceOf(address _account) external view returns(uint256);
}

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
    function decimals() external view returns (uint8);
}

interface ICRVDeployer {
    function deploy_metapool(
        address _bp, 
        string calldata _name, 
        string calldata _symbol, 
        address _coin, 
        uint256 _A, 
        uint256 _fee
    ) external returns (address);
}

interface ICRVMetaPool {
    function add_liquidity(uint256[2] memory amounts_in, uint256 min_mint_amount) external payable returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
    function coins(uint256 i) external view returns (address);
    function balances(uint256 i) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
    function base_pool() external view returns(address);
    function remove_liquidity(uint256 amount, uint256[2] memory min_amounts_out) external returns (uint256[2] memory);
    function remove_liquidity_one_coin(uint256 token_amount, int128 index, uint256 min_amount) external;
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}

interface ICRVPlainPoolFBP {
    function add_liquidity(uint256[2] memory amounts_in, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[3] memory amounts_in, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[4] memory amounts_in, uint256 min_mint_amount) external returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
    function coins(uint256 i) external view returns (address);
    function balances(uint256 i) external view returns (uint256);
    function remove_liquidity(uint256 amount, uint256[2] memory min_amounts_out) external returns (uint256[2] memory);
    function remove_liquidity(uint256 amount, uint256[3] memory min_amounts_out) external returns (uint256[3] memory);
    function remove_liquidity(uint256 amount, uint256[4] memory min_amounts_out) external returns (uint256[4] memory);
    function remove_liquidity_one_coin(uint256 token_amount, int128 index, uint256 min_amount) external;
    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);
    function get_virtual_price() external view returns (uint256);
    function exchange(int128 indexTokenIn, int128 indexTokenOut, uint256 amountIn, uint256 minToReceive) external returns (uint256 amountReceived);
}

interface ICRVPlainPool3CRV {
    function add_liquidity(uint256[3] memory amounts_in, uint256 min_mint_amount) external;
    function coins(uint256 i) external view returns (address);
    function remove_liquidity(uint256 amount, uint256[3] memory min_amounts_out) external;
}

interface ICRV_PP_128_NP {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

interface ICRV_MP_256 {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
}

interface ISushiRouter {
     function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface ISushiFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Router01 {
     function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

interface IAggregationExecutor {
    function callBytes(address msgSender, bytes calldata data) external payable;  // 0x2636f7f8
}

interface IAggregationRouterV4 {
    function swap(IAggregationExecutor caller, SwapDescription memory desc, bytes calldata data) external payable;
}

interface ILendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockStablecoin is ERC20 {
    uint8 dec;

    constructor(
        string memory name,
        string memory symbol,
        uint8 _dec
    ) ERC20(name, symbol) {
        dec = _dec;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return dec;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "./libraries/ZivoeOwnableLocked.sol";

interface DAO_IZivoeGlobals {
    /// @notice Returns "true" when a locker is whitelisted, for DAO interactions and accounting accessibility.
    /// @param locker The address of the locker to check for.
    function isLocker(address locker) external view returns (bool);
}

interface DAO_ILocker {
    /// @notice Migrates specific amount of ERC20 from owner() to locker.
    /// @param  asset The asset to migrate.
    /// @param  amount The amount of "asset" to migrate.
    /// @param  data Accompanying transaction data.
    function pushToLocker(address asset, uint256 amount, bytes calldata data) external;

    /// @notice Migrates entire ERC20 balance from locker to owner().
    /// @param  asset The asset to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLocker(address asset, bytes calldata data) external;

    /// @notice Migrates specific amount of ERC20 from locker to owner().
    /// @param  asset The asset to migrate.
    /// @param  amount The amount of "asset" to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLockerPartial(address asset, uint256 amount, bytes calldata data) external;

    /// @notice Migrates specific amounts of ERC20s from owner() to locker.
    /// @param  assets The assets to migrate.
    /// @param  amounts The amounts of "assets" to migrate, corresponds to "assets" by position in array.   
    /// @param  data Accompanying transaction data.
    function pushToLockerMulti(address[] calldata assets, uint256[] calldata amounts, bytes[] calldata data) external;

    /// @notice Migrates full amount of ERC20s from locker to owner().
    /// @param  assets The assets to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLockerMulti(address[] calldata assets, bytes[] calldata data) external;

    /// @notice Migrates specific amounts of ERC20s from locker to owner().
    /// @param  assets The assets to migrate.
    /// @param  amounts The amounts of "assets" to migrate, corresponds to "assets" by position in array.
    /// @param  data Accompanying transaction data.
    function pullFromLockerMultiPartial(address[] calldata assets, uint256[] calldata amounts, bytes[] calldata data) external;

    /// @notice Migrates an ERC721 from owner() to locker.
    /// @param  asset The NFT contract.
    /// @param  tokenId The ID of the NFT to migrate.
    /// @param  data Accompanying transaction data.  
    function pushToLockerERC721(address asset, uint256 tokenId, bytes calldata data) external;

    /// @notice Migrates an ERC721 from locker to owner().
    /// @param  asset The NFT contract.
    /// @param  tokenId The ID of the NFT to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLockerERC721(address asset, uint256 tokenId, bytes calldata data) external;

    /// @notice Migrates ERC721s from owner() to locker.
    /// @param  assets The NFT contracts.
    /// @param  tokenIds The IDs of the NFTs to migrate.
    /// @param  data Accompanying transaction data.   
    function pushToLockerMultiERC721(address[] calldata assets, uint256[] calldata tokenIds, bytes[] calldata data) external;

    /// @notice Migrates ERC721s from locker to owner().
    /// @param  assets The NFT contracts.
    /// @param  tokenIds The IDs of the NFTs to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLockerMultiERC721(address[] calldata assets, uint256[] calldata tokenIds, bytes[] calldata data) external;

    /// @notice Migrates ERC1155 assets from owner() to locker.
    /// @param  asset The ERC1155 contract.
    /// @param  ids The IDs of the assets within the ERC1155 to migrate.
    /// @param  amounts The amounts to migrate.
    /// @param  data Accompanying transaction data.   
    function pushToLockerERC1155(
        address asset, 
        uint256[] calldata ids, 
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /// @notice Migrates ERC1155 assets from locker to owner().
    /// @param  asset The ERC1155 contract.
    /// @param  ids The IDs of the assets within the ERC1155 to migrate.
    /// @param  amounts The amounts to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLockerERC1155(
        address asset, 
        uint256[] calldata ids, 
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /// @notice Permission for calling pushToLocker().
    function canPush() external view returns (bool);

    /// @notice Permission for calling pullFromLocker().  
    function canPull() external view returns (bool);

    /// @notice Permission for calling pullFromLockerPartial().
    function canPullPartial() external view returns (bool);

    /// @notice Permission for calling pushToLockerMulti().  
    function canPushMulti() external view returns (bool);

    /// @notice Permission for calling pullFromLockerMulti(). 
    function canPullMulti() external view returns (bool);

    /// @notice Permission for calling pullFromLockerMultiPartial().   
    function canPullMultiPartial() external view returns (bool);

    /// @notice Permission for calling pushToLockerERC721().
    function canPushERC721() external view returns (bool);

    /// @notice Permission for calling pullFromLockerERC721().
    function canPullERC721() external view returns (bool);

    /// @notice Permission for calling pushToLockerMultiERC721().
    function canPushMultiERC721() external view returns (bool);

    /// @notice Permission for calling pullFromLockerMultiERC721().    
    function canPullMultiERC721() external view returns (bool);

    /// @notice Permission for calling pushToLockerERC1155().    
    function canPushERC1155() external view returns (bool);

    /// @notice Permission for calling pullFromLockerERC1155().   
    function canPullERC1155() external view returns (bool);
}

interface DAO_IERC721 {
    /// @notice Safely transfers `tokenId` token from `from` to `to`
    /// @param from The address sending the token.
    /// @param to The address receiving the token.
    /// @param tokenId The ID of the token to transfer.
    /// @param _data Accompanying transaction data. 
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;

    /// @notice Gives permission to `to` to transfer `tokenId` token to another account.
    /// The approval is cleared when the token is transferred.
    /// @param to The address to grant permission to.
    /// @param tokenId The number of the tokenId to give approval for.
    function approve(address to, uint256 tokenId) external;

}

interface DAO_IERC1155 {
    /// @notice Grants or revokes permission to `operator` to transfer the caller's tokens.
    /// @param operator The address to grant permission to.
    /// @param approved "true" = approve, "false" = don't approve or cancel approval.
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Transfers `amount` tokens of token type `id` from `from` to `to`.
    /// @param from The address sending the tokens.
    /// @param to The address receiving the tokens.
    /// @param ids An array with the tokenIds to send.
    /// @param amounts An array of corresponding amount of each tokenId to send.
    /// @param data Accompanying transaction data. 
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/// @notice This contract escrows unused or unallocated capital.
///         This contract has the following responsibilities:
///          - Deployment and redemption of capital:
///             (a) Pushing assets to a locker.
///             (b) Pulling assets from a locker.
///           - Enforces a whitelist of lockers through which pushing and pulling capital can occur.
///           - This whitelist is modifiable.
contract ZivoeDAO is ERC1155Holder, ERC721Holder, ZivoeOwnableLocked, ReentrancyGuard {
    
    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    address public immutable GBL;   /// @dev The ZivoeGlobals contract.



    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeDAO.sol contract.
    /// @param _GBL The ZivoeGlobals contract.
    constructor(address _GBL) {
        GBL = _GBL;
    }



    // ------------
    //    Events
    // ------------

    /// @notice Emitted during push(), pushMulti().
    /// @param  locker The locker receiving "asset".
    /// @param  asset The asset being pushed.
    /// @param  amount The amount of "asset" being pushed.
    /// @param  data Accompanying transaction data.
    event Pushed(address indexed locker, address indexed asset, uint256 amount, bytes data);

    /// @notice Emitted during pull(), pullMulti().
    /// @param  locker The locker "asset" is pulled from.
    /// @param  asset The asset being pulled.
    /// @param  data Accompanying transaction data.
    event Pulled(address indexed locker, address indexed asset, bytes data);

    /// @notice Emitted during pullPartial(), pullMultiPartial().
    /// @param  locker The locker "asset" is pulled from.
    /// @param  asset The asset being pulled.
    /// @param  amount The amount of "asset" being pulled (or could represent a percentage, in basis points).
    /// @param  data Accompanying transaction data.
    event PulledPartial(address indexed locker, address indexed asset, uint256 amount, bytes data);

    /// @notice Emitted during pushERC721(), pushMultiERC721().
    /// @param  locker The locker receiving "assets".
    /// @param  asset The asset being pushed.
    /// @param  tokenId The ID for a given "asset" / NFT.
    /// @param  data Accompanying data for the transaction.
    event PushedERC721(address indexed locker, address indexed asset, uint256 indexed tokenId, bytes data);
    
    /// @notice Emitted during pullERC721(), pullMultiERC721().
    /// @param  locker The locker "assets" are pulled from.
    /// @param  asset The asset being pulled.
    /// @param  tokenId The ID for a given "asset" / NFT.
    /// @param  data Accompanying data for the transaction.
    event PulledERC721(address indexed locker, address indexed asset, uint256 indexed tokenId, bytes data);
    
    /// @notice Emitted during pushERC1155Batch().
    /// @param  locker The locker receiving "assets".
    /// @param  asset The asset being pushed.
    /// @param  ids The IDs for a given "asset" / ERC1155, corresponds to "amounts".
    /// @param  amounts The amount of "id" to transfer.
    /// @param  data Accompanying data for the transaction.
    event PushedERC1155(address indexed locker, address indexed asset, uint256[] ids, uint256[] amounts, bytes data);

    /// @notice Emitted during pullERC1155Batch().
    /// @param  locker The locker "assets" are pulled from.
    /// @param  asset The asset being pushed.
    /// @param  ids The IDs for a given "asset" / ERC1155, corresponds to "amounts".
    /// @param  amounts The amount of "id" to transfer.
    /// @param  data Accompanying data for the transaction.
    event PulledERC1155(address indexed locker, address indexed asset, uint256[] ids, uint256[] amounts, bytes data);

    

    // ----------------
    //    Functions
    // ----------------

    /// @notice Migrates capital from DAO to locker.
    /// @param  locker  The locker to push capital to.
    /// @param  asset   The asset to push to locker.
    /// @param  amount  The amount of "asset" to push.
    /// @param  data Accompanying transaction data.
    function push(address locker, address asset, uint256 amount, bytes calldata data) external onlyOwner nonReentrant {
        require(DAO_IZivoeGlobals(GBL).isLocker(locker), "ZivoeDAO::push() !DAO_IZivoeGlobals(GBL).isLocker(locker)");
        require(DAO_ILocker(locker).canPush(), "ZivoeDAO::push() !DAO_ILocker(locker).canPush()");

        emit Pushed(locker, asset, amount, data);
        IERC20(asset).safeApprove(locker, amount);
        DAO_ILocker(locker).pushToLocker(asset, amount, data);
        if (IERC20(asset).allowance(address(this), locker) > 0) {
            IERC20(asset).safeApprove(locker, 0);
        }
    }

    /// @notice Pulls capital from locker to DAO.
    /// @param  locker The locker to pull from.
    /// @param  asset The asset to pull.
    /// @param  data Accompanying transaction data.
    function pull(address locker, address asset, bytes calldata data) external onlyOwner nonReentrant {
        require(DAO_ILocker(locker).canPull(), "ZivoeDAO::pull() !DAO_ILocker(locker).canPull()");

        emit Pulled(locker, asset, data);
        DAO_ILocker(locker).pullFromLocker(asset, data);
    }

    /// @notice Pulls capital from locker to DAO.
    /// @dev    The input "amount" might represent a ratio, BIPS, or an absolute amount depending on locker.
    /// @param  locker The locker to pull from.
    /// @param  asset The asset to pull.
    /// @param  amount The amount to pull (may not refer to "asset", but rather a different asset within the locker).
    /// @param  data Accompanying transaction data.
    function pullPartial(address locker, address asset, uint256 amount, bytes calldata data) external onlyOwner nonReentrant {
        require(DAO_ILocker(locker).canPullPartial(), "ZivoeDAO::pullPartial() !DAO_ILocker(locker).canPullPartial()");

        emit PulledPartial(locker, asset, amount, data);
        DAO_ILocker(locker).pullFromLockerPartial(asset, amount, data);
    }

    /// @notice Migrates multiple types of capital from DAO to locker.
    /// @param  locker  The locker to push capital to.
    /// @param  assets  The assets to push to locker.
    /// @param  amounts The amount of "asset" to push.
    /// @param  data Accompanying transaction data.
    function pushMulti(address locker, address[] calldata assets, uint256[] calldata amounts, bytes[] calldata data) external onlyOwner nonReentrant {
        require(DAO_IZivoeGlobals(GBL).isLocker(locker), "ZivoeDAO::pushMulti() !DAO_IZivoeGlobals(GBL).isLocker(locker)");
        require(assets.length == amounts.length, "ZivoeDAO::pushMulti() assets.length != amounts.length");
        require(amounts.length == data.length, "ZivoeDAO::pushMulti() amounts.length != data.length");
        require(DAO_ILocker(locker).canPushMulti(), "ZivoeDAO::pushMulti() !DAO_ILocker(locker).canPushMulti()");

        for (uint256 i = 0; i < assets.length; i++) {
            IERC20(assets[i]).safeApprove(locker, amounts[i]);
            emit Pushed(locker, assets[i], amounts[i], data[i]);
        }
        DAO_ILocker(locker).pushToLockerMulti(assets, amounts, data);
        for (uint256 i = 0; i < assets.length; i++) {
            if (IERC20(assets[i]).allowance(address(this), locker) > 0) {
                IERC20(assets[i]).safeApprove(locker, 0);
            }
        }
    }

    /// @notice Pulls capital from locker to DAO.
    /// @param  locker The locker to pull from.
    /// @param  assets The assets to pull.
    /// @param  data Accompanying transaction data.
    function pullMulti(address locker, address[] calldata assets, bytes[] calldata data) external onlyOwner nonReentrant {
        require(DAO_ILocker(locker).canPullMulti(), "ZivoeDAO::pullMulti() !DAO_ILocker(locker).canPullMulti()");
        require(assets.length == data.length, "ZivoeDAO::pullMulti() assets.length != data.length");

        for (uint256 i = 0; i < assets.length; i++) {
            emit Pulled(locker, assets[i], data[i]);
        }
        DAO_ILocker(locker).pullFromLockerMulti(assets, data);
    }

    /// @notice Pulls capital from locker to DAO.
    /// @param  locker The locker to pull from.
    /// @param  assets The asset to pull.
    /// @param  amounts The amounts to pull (may not refer to "assets", but rather a different asset within the locker).
    /// @param  data Accompanying transaction data.
    function pullMultiPartial(address locker, address[] calldata assets, uint256[] calldata amounts, bytes[] calldata data) external onlyOwner nonReentrant {
        require(DAO_ILocker(locker).canPullMultiPartial(), "ZivoeDAO::pullMultiPartial() !DAO_ILocker(locker).canPullMultiPartial()");
        require(assets.length == amounts.length, "ZivoeDAO::pullMultiPartial() assets.length != amounts.length");
        require(amounts.length == data.length, "ZivoeDAO::pullMultiPartial() amounts.length != data.length");

        for (uint256 i = 0; i < assets.length; i++) {
            emit PulledPartial(locker, assets[i], amounts[i], data[i]);
        }
        DAO_ILocker(locker).pullFromLockerMultiPartial(assets, amounts, data);
    }
    
    /// @notice Migrates an NFT from the DAO to a locker.
    /// @param  locker  The locker to push an NFT to.
    /// @param  asset The NFT contract.
    /// @param  tokenId The NFT ID to push.
    /// @param  data Accompanying data for the transaction.
    function pushERC721(address locker, address asset, uint256 tokenId, bytes calldata data) external onlyOwner nonReentrant {
        require(DAO_IZivoeGlobals(GBL).isLocker(locker), "ZivoeDAO::pushERC721() !DAO_IZivoeGlobals(GBL).isLocker(locker)");
        require(DAO_ILocker(locker).canPushERC721(), "ZivoeDAO::pushERC721() !DAO_ILocker(locker).canPushERC721()");

        emit PushedERC721(locker, asset, tokenId, data);
        DAO_IERC721(asset).approve(locker, tokenId);
        DAO_ILocker(locker).pushToLockerERC721(asset, tokenId, data);
        // TODO: Unapprove if approval > 0 at end of pushToLockerERC721().
    }

    /// @notice Migrates NFTs from the DAO to a locker.
    /// @param  locker  The locker to push NFTs to.
    /// @param  assets The NFT contracts.
    /// @param  tokenIds The NFT IDs to push.
    /// @param  data Accompanying data for the transaction(s).
    function pushMultiERC721(address locker, address[] calldata assets, uint256[] calldata tokenIds, bytes[] calldata data) external onlyOwner nonReentrant {
        require(DAO_IZivoeGlobals(GBL).isLocker(locker), "ZivoeDAO::pushMultiERC721() !DAO_IZivoeGlobals(GBL).isLocker(locker)");
        require(assets.length == tokenIds.length, "ZivoeDAO::pushMultiERC721() assets.length != tokenIds.length");
        require(tokenIds.length == data.length, "ZivoeDAO::pushMultiERC721() tokenIds.length != data.length");
        require(DAO_ILocker(locker).canPushMultiERC721(), "ZivoeDAO::pushMultiERC721() !DAO_ILocker(locker).canPushMultiERC721()");

        for (uint256 i = 0; i < assets.length; i++) {
            DAO_IERC721(assets[i]).approve(locker, tokenIds[i]);
            emit PushedERC721(locker, assets[i], tokenIds[i], data[i]);
        }
        DAO_ILocker(locker).pushToLockerMultiERC721(assets, tokenIds, data);
        // TODO: Unapprove if approval > 0 at end of pushToLockerMultiERC721().
    }

    /// @notice Pulls an NFT from locker to DAO.
    /// @param  locker The locker to pull from.
    /// @param  asset The NFT contract.
    /// @param  tokenId The NFT ID to pull.
    /// @param  data Accompanying data for the transaction.
    function pullERC721(address locker, address asset, uint256 tokenId, bytes calldata data) external onlyOwner nonReentrant {
        require(DAO_ILocker(locker).canPullERC721(), "ZivoeDAO::pullERC721() !DAO_ILocker(locker).canPullERC721()");

        emit PulledERC721(locker, asset, tokenId, data);
        DAO_ILocker(locker).pullFromLockerERC721(asset, tokenId, data);
    }

    /// @notice Pulls NFTs from locker to DAO.
    /// @param  locker The locker to pull from.
    /// @param  assets The NFT contracts.
    /// @param  tokenIds The NFT IDs to pull.
    /// @param  data Accompanying data for the transaction(s).
    function pullMultiERC721(address locker, address[] calldata assets, uint256[] calldata tokenIds, bytes[] calldata data) external onlyOwner nonReentrant {
        require(DAO_ILocker(locker).canPullMultiERC721(), "ZivoeDAO::pullMultiERC721() !DAO_ILocker(locker).canPullMultiERC721()");
        require(assets.length == tokenIds.length, "ZivoeDAO::pullMultiERC721() assets.length != tokenIds.length");
        require(tokenIds.length == data.length, "ZivoeDAO::pullMultiERC721() tokenIds.length != data.length");

        for (uint256 i = 0; i < assets.length; i++) {
            emit PulledERC721(locker, assets[i], tokenIds[i], data[i]);
        }
        DAO_ILocker(locker).pullFromLockerMultiERC721(assets, tokenIds, data);
    }

    /// @notice Migrates ERC1155 assets from DAO to locker.
    /// @param  locker The locker to push ERC1155 assets to.
    /// @param  asset The ERC1155 asset to push to locker.
    /// @param  ids The ids of "assets" to push.
    /// @param  amounts The amounts of "assets" to push.
    /// @param  data Accompanying data for the transaction.
    function pushERC1155Batch(
            address locker,
            address asset,
            uint256[] calldata ids, 
            uint256[] calldata amounts,
            bytes calldata data
    ) external onlyOwner nonReentrant {
        require(DAO_IZivoeGlobals(GBL).isLocker(locker), "ZivoeDAO::pushERC1155Batch() !DAO_IZivoeGlobals(GBL).isLocker(locker)");
        require(DAO_ILocker(locker).canPushERC1155(), "ZivoeDAO::pushERC1155Batch() !DAO_ILocker(locker).canPushERC1155()");
        require(ids.length == amounts.length, "ZivoeDAO::pushERC1155Batch() ids.length != amounts.length");

        emit PushedERC1155(locker, asset, ids, amounts, data);
        DAO_IERC1155(asset).setApprovalForAll(locker, true);
        DAO_ILocker(locker).pushToLockerERC1155(asset, ids, amounts, data);
        // TODO: Unapprove if approval > 0 at end of pushToLockerERC1155().
    }

    /// @notice Pulls ERC1155 assets from locker to DAO.
    /// @param  locker The locker to pull from.
    /// @param  asset The ERC1155 asset to pull.
    /// @param  ids The ids of "assets" to pull.
    /// @param  amounts The amounts of "assets" to pull.
    /// @param  data Accompanying data for the transaction.
    function pullERC1155Batch(
            address locker,
            address asset,
            uint256[] calldata ids, 
            uint256[] calldata amounts,
            bytes calldata data
    ) external onlyOwner nonReentrant {
        require(DAO_ILocker(locker).canPullERC1155(), "ZivoeDAO::pullERC1155Batch() !DAO_ILocker(locker).canPullERC1155()");
        require(ids.length == amounts.length, "ZivoeDAO::pullERC1155Batch() ids.length != amounts.length");

        emit PulledERC1155(locker, asset, ids, amounts, data);
        DAO_ILocker(locker).pullFromLockerERC1155(asset, ids, amounts, data);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;


import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./libraries/ZivoeMath.sol";
import "./libraries/ZivoeOwnableLocked.sol";

/// @notice    This contract handles the global variables for the Zivoe protocol.
contract ZivoeGlobals is ZivoeOwnableLocked {

    using ZivoeMath for uint256;

    // ---------------------
    //    State Variables
    // ---------------------

    address public DAO;       /// @dev The ZivoeDAO.sol contract.
    address public ITO;       /// @dev The ZivoeITO.sol contract.
    address public stJTT;     /// @dev The ZivoeRewards.sol ($zJTT) contract.
    address public stSTT;     /// @dev The ZivoeRewards.sol ($zSTT) contract.
    address public stZVE;     /// @dev The ZivoeRewards.sol ($ZVE) contract.
    address public vestZVE;   /// @dev The ZivoeRewardsVesting.sol ($ZVE) vesting contract.
    address public YDL;       /// @dev The ZivoeYDL.sol contract.
    address public zJTT;      /// @dev The ZivoeTrancheToken.sol ($zJTT) contract.
    address public zSTT;      /// @dev The ZivoeTrancheToken.sol ($zSTT) contract.
    address public ZVE;       /// @dev The ZivoeToken.sol contract.
    address public ZVL;       /// @dev The Zivoe Laboratory.
    address public ZVT;       /// @dev The ZivoeTranches.sol contract.
    address public GOV;       /// @dev The Governor contract.
    address public TLC;       /// @dev The Timelock contract.

    /// @dev This ratio represents the maximum size allowed for junior tranche, relative to senior tranche.
    ///      A value of 2,000 represent 20%, thus junior tranche at maximum can be 20% the size of senior tranche.
    uint256 public maxTrancheRatioBIPS = 2000;

    /// @dev These two values control the min/max $ZVE minted per stablecoin deposited to ZivoeTranches.sol.
    uint256 public minZVEPerJTTMint = 0;
    uint256 public maxZVEPerJTTMint = 0;

    /// @dev These values represent basis points ratio between zJTT.totalSupply():zSTT.totalSupply() for maximum rewards (affects above slope).
    uint256 public lowerRatioIncentive = 1000;
    uint256 public upperRatioIncentive = 2000;

    /// @dev Tracks net defaults in system.
    uint256 public defaults;

    mapping(address => bool) public isKeeper;               /// @dev Whitelist for keepers, responsible for pre-initiating actions.
    mapping(address => bool) public isLocker;               /// @dev Whitelist for lockers, for DAO interactions and accounting accessibility.
    mapping(address => bool) public stablecoinWhitelist;    /// @dev Whitelist for acceptable stablecoins throughout system (ZVE, YDL).



    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeGlobals.sol contract.
    constructor() { }



    // ------------
    //    Events
    // ------------

    /// @notice Emitted during initializeGlobals().
    /// @param controller The address representing Zivoe Labs / Dev entity.
    event AccessControlSetZVL(address indexed controller);

    /// @notice Emitted during decreaseNetDefaults().
    /// @param locker The locker updating the default amount.
    /// @param amount Amount of defaults decreased.
    /// @param updatedDefaults Total defaults funds after event.
    event DefaultsDecreased(address indexed locker, uint256 amount, uint256 updatedDefaults);

    /// @notice Emitted during increaseNetDefaults().
    /// @param locker The locker updating the default amount.
    /// @param amount Amount of defaults increased.
    /// @param updatedDefaults Total defaults after event.
    event DefaultsIncreased(address indexed locker, uint256 amount, uint256 updatedDefaults);

    /// @notice Emitted during updateIsLocker().
    /// @param  locker  The locker whose status as a locker is being modified.
    /// @param  allowed The boolean value to assign.
    event UpdatedLockerStatus(address indexed locker, bool allowed);

    /// @notice Emitted during updateIsKeeper().
    /// @param  account The address whose status as a keeper is being modified.
    /// @param  status The new status of "account".
    event UpdatedKeeperStatus(address indexed account, bool status);

    /// @notice Emitted during updateMaxTrancheRatio().
    /// @param  oldValue The old value of maxTrancheRatioBIPS.
    /// @param  newValue The new value of maxTrancheRatioBIPS.
    event UpdatedMaxTrancheRatioBIPS(uint256 oldValue, uint256 newValue);

    /// @notice Emitted during updateMinZVEPerJTTMint().
    /// @param  oldValue The old value of minZVEPerJTTMint.
    /// @param  newValue The new value of minZVEPerJTTMint.
    event UpdatedMinZVEPerJTTMint(uint256 oldValue, uint256 newValue);

    /// @notice Emitted during updateMaxZVEPerJTTMint().
    /// @param  oldValue The old value of maxZVEPerJTTMint.
    /// @param  newValue The new value of maxZVEPerJTTMint.
    event UpdatedMaxZVEPerJTTMint(uint256 oldValue, uint256 newValue);

    /// @notice Emitted during updateLowerRatioIncentive().
    /// @param  oldValue The old value of lowerRatioJTT.
    /// @param  newValue The new value of lowerRatioJTT.
    event UpdatedLowerRatioIncentive(uint256 oldValue, uint256 newValue);

    /// @notice Emitted during updateUpperRatioIncentive().
    /// @param  oldValue The old value of upperRatioJTT.
    /// @param  newValue The new value of upperRatioJTT.
    event UpdatedUpperRatioIncentive(uint256 oldValue, uint256 newValue);

    /// @notice Emitted during updateStablecoinWhitelist().
    /// @param  asset The stablecoin to update.
    /// @param  allowed The boolean value to assign.
    event UpdatedStablecoinWhitelist(address indexed asset, bool allowed);



    // ---------------
    //    Modifiers
    // ---------------

    modifier onlyZVL() {
        require(_msgSender() == ZVL, "ZivoeGlobals::onlyZVL() _msgSender() != ZVL");
        _;
    }



    // ---------------
    //    Functions
    // ---------------

    /// @notice Call when a default is resolved, decreases net defaults system-wide.
    /// @dev    The value "amount" should be standardized to WEI.
    /// @param  amount The default amount that has been resolved.
    function decreaseDefaults(uint256 amount) external {
        require(isLocker[_msgSender()], "ZivoeGlobals::decreaseDefaults() !isLocker[_msgSender()]");

        defaults -= amount;
        emit DefaultsDecreased(_msgSender(), amount, defaults);
    }

    /// @notice Call when a default occurs, increases net defaults system-wide.
    /// @dev    The value "amount" should be standardized to WEI.
    /// @param  amount The default amount.
    function increaseDefaults(uint256 amount) external {
        require(isLocker[_msgSender()], "ZivoeGlobals::increaseDefaults() !isLocker[_msgSender()]");

        defaults += amount;
        emit DefaultsIncreased(_msgSender(), amount, defaults);
    }

    /// @notice Initialze the variables within this contract (after all contracts have been deployed).
    /// @dev    This function should only be called once.
    /// @param  globals Array of addresses representing all core system contracts.
    function initializeGlobals(address[] calldata globals) external onlyOwner {
        require(DAO == address(0), "ZivoeGlobals::initializeGlobals() DAO != address(0)");

        emit AccessControlSetZVL(globals[10]);

        DAO     = globals[0];
        ITO     = globals[1];
        stJTT   = globals[2];
        stSTT   = globals[3];
        stZVE   = globals[4];
        vestZVE = globals[5];
        YDL     = globals[6];
        zJTT    = globals[7];
        zSTT    = globals[8];
        ZVE     = globals[9];
        ZVL     = globals[10];
        GOV     = globals[11];
        TLC     = globals[12];
        ZVT     = globals[13];

        stablecoinWhitelist[0x6B175474E89094C44Da98b954EedeAC495271d0F] = true; // DAI
        stablecoinWhitelist[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; // USDC
        stablecoinWhitelist[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; // USDT
        
    }

    /// @notice Transfer ZVL access control to another account.
    /// @param  _ZVL The new address for ZVL.
    function transferZVL(address _ZVL) external onlyZVL {
        ZVL = _ZVL;
        emit AccessControlSetZVL(_ZVL);
    }

    /// @notice Updates the keeper whitelist.
    /// @param  keeper The address of the keeper.
    /// @param  status The status to assign to the "keeper" (true = allowed, false = restricted).
    function updateIsKeeper(address keeper, bool status) external onlyZVL {
        emit UpdatedKeeperStatus(keeper, status);
        isKeeper[keeper] = status;
    }

    /// @notice Modifies the locker whitelist.
    /// @param  locker  The locker to update.
    /// @param  allowed The value to assign (true = permitted, false = prohibited).
    function updateIsLocker(address locker, bool allowed) external onlyZVL {
        emit UpdatedLockerStatus(locker, allowed);
        isLocker[locker] = allowed;
    }

    /// @notice Modifies the stablecoin whitelist.
    /// @param  stablecoin The stablecoin to update.
    /// @param  allowed The value to assign (true = permitted, false = prohibited).
    function updateStablecoinWhitelist(address stablecoin, bool allowed) external onlyZVL {
        emit UpdatedStablecoinWhitelist(stablecoin, allowed);
        stablecoinWhitelist[stablecoin] = allowed;
    }

    /// @notice Updates the maximum size of junior tranche, relative to senior tranche.
    /// @dev    A value of 2,000 represents 20% (basis points), meaning the junior tranche 
    ///         at maximum can be 20% the size of senior tranche.
    /// @param  ratio The new ratio value.
    function updateMaxTrancheRatio(uint256 ratio) external onlyOwner {
        require(ratio <= 3500, "ZivoeGlobals::updateMaxTrancheRatio() ratio > 3500");

        emit UpdatedMaxTrancheRatioBIPS(maxTrancheRatioBIPS, ratio);
        maxTrancheRatioBIPS = ratio;
    }

    /// @notice Updates the minimum $ZVE minted per stablecoin deposited to ZivoeTranches.
    /// @param  min Minimum $ZVE minted per stablecoin.
    function updateMinZVEPerJTTMint(uint256 min) external onlyOwner {
        require(min < maxZVEPerJTTMint, "ZivoeGlobals::updateMinZVEPerJTTMint() min >= maxZVEPerJTTMint");

        emit UpdatedMinZVEPerJTTMint(minZVEPerJTTMint, min);
        minZVEPerJTTMint = min;
    }

    /// @notice Updates the maximum $ZVE minted per stablecoin deposited to ZivoeTranches.
    /// @param  max Maximum $ZVE minted per stablecoin.
    function updateMaxZVEPerJTTMint(uint256 max) external onlyOwner {
        require(max < 0.1 * 10**18, "ZivoeGlobals::updateMaxZVEPerJTTMint() max >= 0.1 * 10**18");

        emit UpdatedMaxZVEPerJTTMint(maxZVEPerJTTMint, max);
        maxZVEPerJTTMint = max; 
    }

    /// @notice Updates the lower ratio between tranches for minting incentivization model.
    /// @dev    A value of 2,000 represents 20%, indicating that minimum $ZVE incentives are offered for
    ///         minting $zJTT (Junior Tranche Tokens) when the actual tranche ratio is 20%.
    ///         Likewise, due to inverse relationship between incentivices for $zJTT and $zSTT minting,
    ///         a value of 2,000 represents 20%, indicating that maximum $ZVE incentives are offered for
    ///         minting $zSTT (Senior Tranche Tokens) when the actual tranche ratio is 20%. 
    /// @param  lowerRatio The lower ratio to handle incentivize thresholds.
    function updateLowerRatioIncentive(uint256 lowerRatio) external onlyOwner {
        require(lowerRatio >= 1000, "ZivoeGlobals::updateLowerRatioIncentive() lowerRatio < 1000");
        require(lowerRatio < upperRatioIncentive, "ZivoeGlobals::updateLowerRatioIncentive() lowerRatio >= upperRatioIncentive");

        emit UpdatedLowerRatioIncentive(lowerRatioIncentive, lowerRatio);
        lowerRatioIncentive = lowerRatio; 
    }

    /// @notice Updates the upper ratio between tranches for minting incentivization model.
    /// @dev    A value of 2,000 represents 20%, indicating that maximum $ZVE incentives are offered for
    ///         minting $zJTT (Junior Tranche Tokens) when the actual tranche ratio is 20%.
    ///         Likewise, due to inverse relationship between incentivices for $zJTT and $zSTT minting,
    ///         a value of 2,000 represents 20%, indicating that minimum $ZVE incentives are offered for
    ///         minting $zSTT (Senior Tranche Tokens) when the actual tranche ratio is 20%. 
    /// @param  upperRatio The upper ratio to handle incentivize thresholds.
    function updateUpperRatioIncentives(uint256 upperRatio) external onlyOwner {
        require(upperRatio <= 2500, "ZivoeGlobals::updateUpperRatioIncentive() upperRatio > 2500");

        emit UpdatedUpperRatioIncentive(upperRatioIncentive, upperRatio);
        upperRatioIncentive = upperRatio; 
    }

    /// @notice Handles WEI standardization of a given asset amount (i.e. 6 decimal precision => 18 decimal precision).
    /// @param amount The amount of a given "asset".
    /// @param asset The asset (ERC-20) from which to standardize the amount to WEI.
    /// @return standardizedAmount The above amount standardized to 18 decimals.
    function standardize(uint256 amount, address asset) external view returns (uint256 standardizedAmount) {
        standardizedAmount = amount;
        
        if (IERC20Metadata(asset).decimals() < 18) {
            standardizedAmount *= 10 ** (18 - IERC20Metadata(asset).decimals());
        } else if (IERC20Metadata(asset).decimals() > 18) {
            standardizedAmount /= 10 ** (IERC20Metadata(asset).decimals() - 18);
        }
    }

    // TODO: Implement access control transfer via ZVL.

    /// @notice Returns total circulating supply of zSTT and zJTT, accounting for defaults via markdowns.
    /// @return zSTTSupply zSTT.totalSupply() adjusted for defaults.
    /// @return zJTTSupply zJTT.totalSupply() adjusted for defaults.
    function adjustedSupplies() external view returns (uint256 zSTTSupply, uint256 zJTTSupply) {
        // Junior tranche decrease by amount of defaults, to a floor of zero.
        uint256 zJTTSupply_unadjusted = IERC20(zJTT).totalSupply();
        zJTTSupply = zJTTSupply_unadjusted.zSub(defaults);

        uint256 zSTTSupply_unadjusted = IERC20(zSTT).totalSupply();
        // Senior tranche decreases if excess defaults exist beyond junior tranche size.
        if (defaults > zJTTSupply_unadjusted) {
            zSTTSupply = zSTTSupply_unadjusted.zSub(defaults.zSub(zJTTSupply_unadjusted));
        }
        else {
            zSTTSupply = zSTTSupply_unadjusted;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./libraries/ZivoeGovernorTimelockControl.sol";
import "./libraries/ZivoeTimelockController.sol";

import "../lib/openzeppelin-contracts/contracts/governance/extensions/GovernorCountingSimple.sol";
import "../lib/openzeppelin-contracts/contracts/governance/extensions/GovernorSettings.sol";
import "../lib/openzeppelin-contracts/contracts/governance/extensions/GovernorVotes.sol";
import "../lib/openzeppelin-contracts/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

contract ZivoeGovernor is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, ZivoeGovernorTimelockControl {
    
    // -----------------
    //    Constructor
    // -----------------

    constructor(IVotes _token, ZivoeTimelockController _timelock)
        Governor("ZivoeGovernor")
        GovernorSettings(1, 45818, 125000 ether)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(10)
        ZivoeGovernorTimelockControl(_timelock)
    { }



    // ---------------
    //    Functions
    // ---------------

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber) public view override(IGovernor, GovernorVotesQuorumFraction) returns (uint256) {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId) public view override(Governor, ZivoeGovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets, 
        uint256[] memory values, 
        bytes[] memory calldatas, 
        string memory description
    )
        public
        override(Governor, IGovernor)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId, 
        address[] memory targets, 
        uint256[] memory values, 
        bytes[] memory calldatas, 
        bytes32 descriptionHash
    )
        internal
        override(Governor, ZivoeGovernorTimelockControl)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets, 
        uint256[] memory values, 
        bytes[] memory calldatas, 
        bytes32 descriptionHash
    )
        internal
        override(Governor, ZivoeGovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, ZivoeGovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId) public view override(Governor, ZivoeGovernorTimelockControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../lib/openzeppelin-contracts/contracts/utils/Context.sol";

interface ITO_IERC20Mintable {
    /// @notice Creates ERC20 tokens and assigns them to an address, increasing the total supply.
    /// @param account The address to send the newly created tokens to.
    /// @param amount The amount of tokens to create and send.
    function mint(address account, uint256 amount) external;
}

interface ITO_IZivoeGlobals {
    /// @notice Returns the address of the ZivoeDAO contract.
    function DAO() external view returns (address);

    /// @notice Returns the address of the ZivoeYDL contract.
    function YDL() external view returns (address);

    /// @notice Returns the address of the ZivoeTrancheToken.sol ($zJTT) contract.
    function zJTT() external view returns (address);

    /// @notice Returns the address of the ZivoeTrancheToken.sol ($zSTT) contract.
    function zSTT() external view returns (address);

    /// @notice Returns the address of the ZivoeToken.sol contract.
    function ZVE() external view returns (address);

    /// @notice Returns the Zivoe Laboratory address.
    function ZVL() external view returns (address);

    /// @notice Returns the address of the ZivoeTranches.sol contract.
    function ZVT() external view returns (address);

    /// @notice Handles WEI standardization of a given asset amount (i.e. 6 decimal precision => 18 decimal precision).
    /// @param amount The amount of a given "asset".
    /// @param asset The asset (ERC-20) from which to standardize the amount to WEI.
    /// @return standardizedAmount The above amount standardized to 18 decimals.
    function standardize(uint256 amount, address asset) external view returns (uint256 standardizedAmount);
}

interface ITO_IZivoeTranches {
    /// @notice Unlocks the ZivoeTranches.sol contract for distributions, sets some initial variables.
    function unlock() external;
}

interface ITO_IZivoeYDL {
    /// @notice Unlocks the ZivoeYDL contract for distributions, initializes values.
    function unlock() external;
}

/// @notice This contract will facilitate the Zivoe ITO ("Initial Tranche Offering").
///         This contract will be permissioned by $zJTT and $zSTT to call mint().
///         This contract will escrow 10% of $ZVE supply for ITO, claimable post-ITO.
///         This contract will support claiming $ZVE based on proportionate amount of liquidity provided during the ITO.
contract ZivoeITO is Context {

    using SafeERC20 for IERC20;
    
    // ---------------------
    //    State Variables
    // ---------------------

    uint256 public start;           /// @dev The unix when the ITO will start.
    uint256 public end;             /// @dev The unix when the ITO will end (airdrop is claimable).
    
    address public immutable GBL;   /// @dev The ZivoeGlobals contract.

    bool public migrated;           /// @dev Identifies if ITO has migrated assets to the DAO.

    mapping(address => bool) public stablecoinWhitelist;    /// @dev Whitelist for stablecoins which can be deposited.
    mapping(address => bool) public airdropClaimed;         /// @dev Tracks if an account has claimed their airdrop.

    mapping(address => uint256) public juniorCredits;       /// @dev Tracks $pZVE (credits) an individual has from juniorDeposit().
    mapping(address => uint256) public seniorCredits;       /// @dev Tracks $pZVE (credits) an individual has from seniorDeposit().

    uint256 private constant operationAllocation = 1000;    /// @dev The amount (in BIPS) of ITO proceeds allocated for operations.
    uint256 private constant BIPS = 10000;



    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeITO.sol contract.
    /// @param _start The unix when the ITO will start.
    /// @param _end The unix when the ITO will end (airdrop is claimable).
    /// @param _GBL The ZivoeGlobals contract.
    constructor (
        uint256 _start,
        uint256 _end,
        address _GBL
    ) {

        require(_start < _end, "ZivoeITO::constructor() _start >= _end");

        start = _start;
        end = _end;
        GBL = _GBL;

        stablecoinWhitelist[0x6B175474E89094C44Da98b954EedeAC495271d0F] = true; // DAI
        stablecoinWhitelist[0x853d955aCEf822Db058eb8505911ED77F175b99e] = true; // FRAX
        stablecoinWhitelist[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; // USDC
        stablecoinWhitelist[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; // USDT

    }



    // ------------
    //    Events
    // ------------

    /// @notice Emitted during depositJunior().
    /// @param  account The account depositing stablecoins to junior tranche.
    /// @param  asset The stablecoin deposited.
    /// @param  amount The amount of stablecoins deposited.
    /// @param  credits The amount of credits earned.
    /// @param  trancheTokens The amount of Zivoe Junior Tranche ($zJTT) tokens minted.
    event JuniorDeposit(address indexed account, address indexed asset, uint256 amount, uint256 credits, uint256 trancheTokens);

    /// @notice Emitted during depositSenior().
    /// @param  account The account depositing stablecoins to senior tranche.
    /// @param  asset The stablecoin deposited.
    /// @param  amount The amount of stablecoins deposited.
    /// @param  credits The amount of credits earned.
    /// @param  trancheTokens The amount of Zivoe Senior Tranche ($zSTT) tokens minted.
    event SeniorDeposit(address indexed account, address indexed asset, uint256 amount, uint256 credits, uint256 trancheTokens);

    /// @notice Emitted during claim().
    /// @param  account The account withdrawing stablecoins from senior tranche.
    /// @param  zSTTClaimed The amount of Zivoe Senior Tranche ($zSTT) tokens received.
    /// @param  zJTTClaimed The amount of Zivoe Junior Tranche ($zJTT) tokens received.
    /// @param  ZVEClaimed The amount of Zivoe ($ZVE) tokens received.
    event AirdropClaimed(address indexed account, uint256 zSTTClaimed, uint256 zJTTClaimed, uint256 ZVEClaimed);

    /// @notice Emitted during migrateDeposits().
    /// @param  DAI Total amount of DAI migrated from the ITO to the DAO and ZVL.
    /// @param  FRAX Total amount of FRAX migrated from the ITO to the DAO and ZVL.
    /// @param  USDC Total amount of USDC migrated from the ITO to the DAO and ZVL.
    /// @param  USDT Total amount of USDT migrated from the ITO to the DAO and ZVL.
    event DepositsMigrated(uint256 DAI, uint256 FRAX, uint256 USDC, uint256 USDT);



    // ---------------
    //    Functions
    // ---------------

    /// @notice Claim $zSTT, $zJTT, and $ZVE after ITO concludes.
    /// @return zSTTClaimed Amount of $zSTT airdropped.
    /// @return zJTTClaimed Amount of $zJTT airdropped.
    /// @return ZVEClaimed Amount of $ZVE airdropped.
    function claim() external returns (uint256 zSTTClaimed, uint256 zJTTClaimed, uint256 ZVEClaimed) {
        require(block.timestamp > end || migrated, "ZivoeITO::claim() block.timestamp <= end && !migrated");

        address caller = _msgSender();

        require(!airdropClaimed[caller], "ZivoeITO::claim() airdropClaimeded[caller]");
        require(seniorCredits[caller] > 0 || juniorCredits[caller] > 0, "ZivoeITO::claim() seniorCredits[caller] == 0 && juniorCredits[caller] == 0");

        airdropClaimed[caller] = true;

        // Temporarily store credit values, decrease them to 0 immediately after.
        uint256 seniorCreditsOwned = seniorCredits[caller];
        uint256 juniorCreditsOwned = juniorCredits[caller];

        seniorCredits[caller] = 0;
        juniorCredits[caller] = 0;

        // Calculate proportion of $ZVE awarded based on $pZVE credits.
        uint256 upper = seniorCreditsOwned + juniorCreditsOwned;
        uint256 middle = IERC20(ITO_IZivoeGlobals(GBL).ZVE()).totalSupply() / 10;
        uint256 lower = IERC20(ITO_IZivoeGlobals(GBL).zSTT()).totalSupply() * 3 + IERC20(ITO_IZivoeGlobals(GBL).zJTT()).totalSupply();

        emit AirdropClaimed(caller, seniorCreditsOwned / 3, juniorCreditsOwned, upper * middle / lower);

        IERC20(ITO_IZivoeGlobals(GBL).zJTT()).safeTransfer(caller, juniorCreditsOwned);
        IERC20(ITO_IZivoeGlobals(GBL).zSTT()).safeTransfer(caller, seniorCreditsOwned / 3);
        IERC20(ITO_IZivoeGlobals(GBL).ZVE()).safeTransfer(caller, upper * middle / lower);

        return (
            seniorCreditsOwned / 3,
            juniorCreditsOwned,
            upper * middle / lower
        );
    }

    /// @notice Deposit stablecoins into the junior tranche.
    ///         Mints Zivoe Junior Tranche ($zJTT) tokens and increases airdrop credits.
    /// @param  amount The amount to deposit.
    /// @param  asset The asset to deposit.
    function depositJunior(uint256 amount, address asset) external { 
        require(block.timestamp >= start, "ZivoeITO::depositJunior() block.timestamp < start");
        require(block.timestamp < end, "ZivoeITO::depositJunior() block.timestamp >= end");
        require(!migrated, "ZivoeITO::depositJunior() migrated");
        require(stablecoinWhitelist[asset], "ZivoeITO::depositJunior() !stablecoinWhitelist[asset]");

        address caller = _msgSender();
        
        uint256 standardizedAmount = ITO_IZivoeGlobals(GBL).standardize(amount, asset);

        juniorCredits[caller] += standardizedAmount;

        emit JuniorDeposit(caller, asset, amount, standardizedAmount, standardizedAmount);

        IERC20(asset).safeTransferFrom(caller, address(this), amount);
        ITO_IERC20Mintable(ITO_IZivoeGlobals(GBL).zJTT()).mint(address(this), standardizedAmount);
    }

    /// @notice Deposit stablecoins into the senior tranche.
    ///         Mints Zivoe Senior Tranche ($zSTT) tokens and increases airdrop credits.
    /// @param  amount The amount to deposit.
    /// @param  asset The asset to deposit.
    function depositSenior(uint256 amount, address asset) external {
        require(block.timestamp >= start, "ZivoeITO::depositSenior() block.timestamp < start");
        require(block.timestamp < end, "ZivoeITO::depositSenior() block.timestamp >= end");
        require(!migrated, "ZivoeITO::depositSenior() migrated");
        require(stablecoinWhitelist[asset], "ZivoeITO::depositSenior() !stablecoinWhitelist[asset]");

        address caller = _msgSender();

        uint256 standardizedAmount = ITO_IZivoeGlobals(GBL).standardize(amount, asset);

        seniorCredits[caller] += standardizedAmount * 3;

        emit SeniorDeposit(caller, asset, amount, standardizedAmount * 3, standardizedAmount);

        IERC20(asset).safeTransferFrom(caller, address(this), amount);
        ITO_IERC20Mintable(ITO_IZivoeGlobals(GBL).zSTT()).mint(address(this), standardizedAmount);
    }

    /// @notice Migrate tokens to DAO post-ITO.
    /// @dev    Only callable when block.timestamp > _concludeUnix.
    function migrateDeposits() external {
        if (_msgSender() != ITO_IZivoeGlobals(GBL).ZVL()) {
            require(
                block.timestamp > end,  
                "ZivoeITO::migrateDeposits() block.timestamp <= end"
            );
        }
        require(!migrated, "ZivoeITO::migrateDeposits() migrated");
        
        migrated = true;

        emit DepositsMigrated(
            IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).balanceOf(address(this)),
            IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e).balanceOf(address(this)),
            IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(address(this)),
            IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).balanceOf(address(this))
        );
    
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).safeTransfer(
            ITO_IZivoeGlobals(GBL).ZVL(),
            IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).balanceOf(address(this)) * operationAllocation / BIPS // DAI
        );
        IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e).safeTransfer(
            ITO_IZivoeGlobals(GBL).ZVL(),
            IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e).balanceOf(address(this)) * operationAllocation / BIPS // FRAX
        );
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).safeTransfer(
            ITO_IZivoeGlobals(GBL).ZVL(),
            IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(address(this)) * operationAllocation / BIPS // USDC
        );
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).safeTransfer(
            ITO_IZivoeGlobals(GBL).ZVL(),
            IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).balanceOf(address(this)) * operationAllocation / BIPS // USDT
        );
    
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).safeTransfer(
            ITO_IZivoeGlobals(GBL).DAO(),
            IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).balanceOf(address(this))     // DAI
        );
        IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e).safeTransfer(
            ITO_IZivoeGlobals(GBL).DAO(),
            IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e).balanceOf(address(this))     // FRAX
        );
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).safeTransfer(
            ITO_IZivoeGlobals(GBL).DAO(),
            IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(address(this))     // USDC
        );
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).safeTransfer(
            ITO_IZivoeGlobals(GBL).DAO(),
            IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).balanceOf(address(this))     // USDT
        );

        ITO_IZivoeYDL(ITO_IZivoeGlobals(GBL).YDL()).unlock();
        ITO_IZivoeTranches(ITO_IZivoeGlobals(GBL).ZVT()).unlock();
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./libraries/ZivoeOwnableLocked.sol";

interface ZivoeLocker_IERC721 {
    /// @notice Safely transfers `tokenId` token from `from` to `to`.
    /// @param from The address sending the token.
    /// @param to The address receiving the token.
    /// @param tokenId The ID of the token to transfer.
    /// @param _data Accompanying transaction data. 
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;

    /// @notice Gives permission to `to` to transfer `tokenId` token to another account.
    /// The approval is cleared when the token is transferred.
    /// @param to The address to grant permission to.
    /// @param tokenId The number of the tokenId to give approval for.
    function approve(address to, uint256 tokenId) external;
}

interface ZivoeLocker_IERC1155 {
    /// @notice Grants or revokes permission to `operator` to transfer the caller's tokens.
    /// @param operator The address to grant permission to.
    /// @param approved "true" = approve, "false" = don't approve or cancel approval.
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Transfers `amount` tokens of token type `id` from `from` to `to`.
    /// @param from The address sending the tokens.
    /// @param to The address receiving the tokens.
    /// @param ids An array with the tokenIds to send.
    /// @param amounts An array of corresponding amount of each tokenId to send.
    /// @param data Accompanying transaction data. 
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/// @notice  This contract standardizes communication between the DAO and lockers.
abstract contract ZivoeLocker is ZivoeOwnableLocked, ERC1155Holder, ERC721Holder {
    
    using SafeERC20 for IERC20;

    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeLocker.sol contract.
    constructor() {}



    // ---------------
    //    Functions
    // ---------------

    /// @notice Permission for calling pushToLocker().
    function canPush() public virtual view returns (bool) {
        return false;
    }

    /// @notice Permission for calling pullFromLocker().
    function canPull() public virtual view returns (bool) {
        return false;
    }

    /// @notice Permission for calling pullFromLockerPartial().
    function canPullPartial() public virtual view returns (bool) {
        return false;
    }

    /// @notice Permission for calling pushToLockerMulti().
    function canPushMulti() public virtual view returns (bool) {
        return false;
    }

    /// @notice Permission for calling pullFromLockerMulti().
    function canPullMulti() public virtual view returns (bool) {
        return false;
    }

    /// @notice Permission for calling pullFromLockerMultiPartial().
    function canPullMultiPartial() public virtual view returns (bool) {
        return false;
    }

    /// @notice Permission for calling pushToLockerERC721().
    function canPushERC721() public virtual view returns (bool) {
        return false;
    }

    /// @notice Permission for calling pullFromLockerERC721().
    function canPullERC721() public virtual view returns (bool) {
        return false;
    }

    /// @notice Permission for calling pushToLockerMultiERC721().
    function canPushMultiERC721() public virtual view returns (bool) {
        return false;
    }

    /// @notice Permission for calling pullFromLockerMultiERC721().
    function canPullMultiERC721() public virtual view returns (bool) {
        return false;
    }

    /// @notice Permission for calling pushToLockerERC1155().
    function canPushERC1155() public virtual view returns (bool) {
        return false;
    }

    /// @notice Permission for calling pullFromLockerERC1155().
    function canPullERC1155() public virtual view returns (bool) {
        return false;
    }

    /// @notice Migrates specific amount of ERC20 from owner() to locker.
    /// @param  asset The asset to migrate.
    /// @param  amount The amount of "asset" to migrate.
    /// @param  data Accompanying transaction data.
    function pushToLocker(address asset, uint256 amount, bytes calldata data) external virtual onlyOwner {
        require(canPush(), "ZivoeLocker::pushToLocker() !canPush()");

        IERC20(asset).safeTransferFrom(owner(), address(this), amount);
    }

    /// @notice Migrates entire ERC20 balance from locker to owner().
    /// @param  asset The asset to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLocker(address asset, bytes calldata data) external virtual onlyOwner {
        require(canPull(), "ZivoeLocker::pullFromLocker() !canPull()");

        IERC20(asset).safeTransfer(owner(), IERC20(asset).balanceOf(address(this)));
    }

    /// @notice Migrates specific amount of ERC20 from locker to owner().
    /// @param  asset The asset to migrate.
    /// @param  amount The amount of "asset" to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLockerPartial(address asset, uint256 amount, bytes calldata data) external virtual onlyOwner {
        require(canPullPartial(), "ZivoeLocker::pullFromLockerPartial() !canPullPartial()");

        IERC20(asset).safeTransfer(owner(), amount);
    }

    /// @notice Migrates specific amounts of ERC20s from owner() to locker.
    /// @param  assets The assets to migrate.
    /// @param  amounts The amounts of "assets" to migrate, corresponds to "assets" by position in array.
    /// @param  data Accompanying transaction data.
    function pushToLockerMulti(address[] calldata assets, uint256[] calldata amounts, bytes[] calldata data) external virtual onlyOwner {
        require(canPushMulti(), "ZivoeLocker::pushToLockerMulti() !canPushMulti()");

        for (uint256 i = 0; i < assets.length; i++) {
            IERC20(assets[i]).safeTransferFrom(owner(), address(this), amounts[i]);
        }
    }

    /// @notice Migrates full amount of ERC20s from locker to owner().
    /// @param  assets The assets to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLockerMulti(address[] calldata assets, bytes[] calldata data) external virtual onlyOwner {
        require(canPullMulti(), "ZivoeLocker::pullFromLockerMulti() !canPullMulti()");

        for (uint256 i = 0; i < assets.length; i++) {
            IERC20(assets[i]).safeTransfer(owner(), IERC20(assets[i]).balanceOf(address(this)));
        }
    }

    /// @notice Migrates specific amounts of ERC20s from locker to owner().
    /// @param  assets The assets to migrate.
    /// @param  amounts The amounts of "assets" to migrate, corresponds to "assets" by position in array.
    /// @param  data Accompanying transaction data.
    function pullFromLockerMultiPartial(address[] calldata assets, uint256[] calldata amounts, bytes[] calldata data) external virtual onlyOwner {
        require(canPullMultiPartial(), "ZivoeLocker::pullFromLockerMultiPartial() !canPullMultiPartial()");

        for (uint256 i = 0; i < assets.length; i++) {
            IERC20(assets[i]).safeTransfer(owner(), amounts[i]);
        }
    }

    /// @notice Migrates an ERC721 from owner() to locker.
    /// @param  asset The NFT contract.
    /// @param  tokenId The ID of the NFT to migrate.
    /// @param  data Accompanying transaction data.
    function pushToLockerERC721(address asset, uint256 tokenId, bytes calldata data) external virtual onlyOwner {
        require(canPushERC721(), "ZivoeLocker::pushToLockerERC721() !canPushERC721()");

        ZivoeLocker_IERC721(asset).safeTransferFrom(owner(), address(this), tokenId, data);
    }

    /// @notice Migrates an ERC721 from locker to owner().
    /// @param  asset The NFT contract.
    /// @param  tokenId The ID of the NFT to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLockerERC721(address asset, uint256 tokenId, bytes calldata data) external virtual onlyOwner {
        require(canPullERC721(), "ZivoeLocker::pullFromLockerERC721() !canPullERC721()");

        ZivoeLocker_IERC721(asset).safeTransferFrom(address(this), owner(), tokenId, data);
    }

    /// @notice Migrates ERC721s from owner() to locker.
    /// @param  assets The NFT contracts.
    /// @param  tokenIds The IDs of the NFTs to migrate.
    /// @param  data Accompanying transaction data.
    function pushToLockerMultiERC721(address[] calldata assets, uint256[] calldata tokenIds, bytes[] calldata data) external virtual onlyOwner {
        require(canPushMultiERC721(), "ZivoeLocker::pushToLockerMultiERC721() !canPushMultiERC721()");

        for (uint256 i = 0; i < assets.length; i++) {
           ZivoeLocker_IERC721(assets[i]).safeTransferFrom(owner(), address(this), tokenIds[i], data[i]);
        }
    }

    /// @notice Migrates ERC721s from locker to owner().
    /// @param  assets The NFT contracts.
    /// @param  tokenIds The IDs of the NFTs to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLockerMultiERC721(address[] calldata assets, uint256[] calldata tokenIds, bytes[] calldata data) external virtual onlyOwner {
        require(canPullMultiERC721(), "ZivoeLocker::pullFromLockerMultiERC721() !canPullMultiERC721()");

        for (uint256 i = 0; i < assets.length; i++) {
           ZivoeLocker_IERC721(assets[i]).safeTransferFrom(address(this), owner(), tokenIds[i], data[i]);
        }
    }

    /// @notice Migrates ERC1155 assets from owner() to locker.
    /// @param  asset The ERC1155 contract.
    /// @param  ids The IDs of the assets within the ERC1155 to migrate.
    /// @param  amounts The amounts to migrate.
    /// @param  data Accompanying transaction data.
    function pushToLockerERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external virtual onlyOwner {
        require(canPushERC1155(), "ZivoeLocker::pushToLockerERC1155() !canPushERC1155()");

        ZivoeLocker_IERC1155(asset).safeBatchTransferFrom(owner(), address(this), ids, amounts, data);
    }

    /// @notice Migrates ERC1155 assets from locker to owner().
    /// @param  asset The ERC1155 contract.
    /// @param  ids The IDs of the assets within the ERC1155 to migrate.
    /// @param  amounts The amounts to migrate.
    /// @param  data Accompanying transaction data.
    function pullFromLockerERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external virtual onlyOwner {
        require(canPullERC1155(), "ZivoeLocker::pullFromLockerERC1155() !canPullERC1155()");
        
        ZivoeLocker_IERC1155(asset).safeBatchTransferFrom(address(this), owner(), ids, amounts, data);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "./libraries/ZivoeOwnableLocked.sol";

/// @notice This contract facilitates staking and yield distribution.
///         This contract has the following responsibilities:
///           - Allows staking and unstaking of modular "stakingToken".
///           - Allows claiming yield distributed / "deposited" to this contract.
///           - Allows multiple assets to be added as "rewardToken" for distributions.
///           - Vests rewardTokens linearly overtime to stakers.
contract ZivoeRewards is ReentrancyGuard, ZivoeOwnableLocked {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    struct Reward {
        uint256 rewardsDuration;        /// @dev How long rewards take to vest, e.g. 30 days.
        uint256 periodFinish;           /// @dev When current rewards will finish vesting.
        uint256 rewardRate;             /// @dev Rewards emitted per second.
        uint256 lastUpdateTime;         /// @dev Last time this data struct was updated.
        uint256 rewardPerTokenStored;   /// @dev Last snapshot of rewardPerToken taken.
    }

    address public immutable GBL;       /// @dev The ZivoeGlobals contract.

    address[] public rewardTokens;      /// @dev Array of ERC20 tokens distributed as rewards (if present).

    uint256 private _totalSupply;       /// @dev Total supply of (non-transferrable) LP tokens for reards contract.

    mapping(address => Reward) public rewardData;   /// @dev Contains rewards information for each rewardToken.

    mapping(address => mapping(address => uint256)) public rewards;                 /// @dev The order is account -> rewardAsset -> amount.
    mapping(address => mapping(address => uint256)) public accountRewardPerTokenPaid;  /// @dev The order is account -> rewardAsset -> amount.

    mapping(address => uint256) private _balances;  /// @dev Contains LP token balance of each account (is 1:1 ratio with amount deposited).

    IERC20 public stakingToken;         /// @dev IERC20 wrapper for the stakingToken (deposited to receive LP tokens).



    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeRewards.sol contract.
    /// @param _stakingToken The ERC20 asset deposited to mint LP tokens (and returned when burning LP tokens).
    /// @param _GBL The ZivoeGlobals contract.
    constructor(
        address _stakingToken,
        address _GBL
    ) {
        stakingToken = IERC20(_stakingToken);
        GBL = _GBL;
    }



    // ------------
    //    Events
    // ------------

    /// @notice Emitted during addReward().
    /// @param  reward The asset that's being distributed.
    event RewardAdded(address indexed reward);

    /// @notice Emitted during depositReward().
    /// @param  reward The asset that's being deposited.
    /// @param  amount The amout deposited.
    /// @param  depositor The _msgSender() who deposited said reward.
    event RewardDeposited(address indexed reward, uint256 amount, address indexed depositor);

    /// @notice Emitted during stake().
    /// @param  account The account staking "stakingToken".
    /// @param  amount The amount of  "stakingToken" staked.
    event Staked(address indexed account, uint256 amount);

    /// @notice Emitted during withdraw().
    /// @param  account The account withdrawing "stakingToken".
    /// @param  amount The amount of "stakingToken" withdrawn.
    event Withdrawn(address indexed account, uint256 amount);

    /// @notice Emitted during getRewardAt().
    /// @param  account The account receiving a reward.
    /// @param  rewardsToken The asset that's being distributed.
    /// @param  reward The amount of "rewardsToken" distributed.
    event RewardDistributed(address indexed account, address indexed rewardsToken, uint256 reward);



    // ---------------
    //    Modifiers
    // ---------------

    /// @notice This modifier ensures account rewards information is updated BEFORE mutative actions.
    /// @param account The account to update personal rewards information if account != address(0).
    modifier updateReward(address account) {
        for (uint256 i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = rewardPerToken(token);
            rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(0)) {
                rewards[account][token] = earned(account, token);
                accountRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
        _;
    }



    // ---------------
    //    Functions
    // ---------------

    /// @notice Returns the amount of tokens owned by "account", received when depositing via stake().
    /// @param account The account to view information of.
    /// @return amount The amount of tokens owned by "account".
    function balanceOf(address account) external view returns (uint256 amount) {
        return _balances[account];
    }

    /// @notice Returns the amount of tokens in existence; these are minted and burned when depositing or withdrawing.
    /// @return amount The amount of tokens in existence.
    function totalSupply() external view returns (uint256 amount) {
        return _totalSupply;
    }

    /// @notice Returns the rewards earned of a specific rewardToken for an address.
    /// @param account The account to view information of.
    /// @param rewardAsset The asset earned as a reward.
    /// @return amount The amount of rewards earned.
    function viewRewards(address account, address rewardAsset) external view returns (uint256 amount) {
        return rewards[account][rewardAsset];
    }

    /// @notice Returns the last snapshot of rewardPerTokenStored taken for a reward asset.
    /// @param account The account to view information of.
    /// @param rewardAsset The reward token for which we want to return the rewardPerTokenstored.
    /// @return amount The latest up-to-date value of rewardPerTokenStored.
    function viewAccountRewardPerTokenPaid(address account, address rewardAsset) external view returns (uint256 amount) {
        return accountRewardPerTokenPaid[account][rewardAsset];
    }
    
    /// @notice Returns the total amount of rewards being distributed to everyone for current rewardsDuration.
    /// @param  _rewardsToken The asset that's being distributed.
    /// @return amount The amount of rewards being distributed.
    function getRewardForDuration(address _rewardsToken) external view returns (uint256 amount) {
        return rewardData[_rewardsToken].rewardRate.mul(rewardData[_rewardsToken].rewardsDuration);
    }

    /// @notice Provides information on the rewards available for claim.
    /// @param account The account to view information of.
    /// @param _rewardsToken The asset that's being distributed.
    /// @return amount The amount of rewards earned.
    function earned(address account, address _rewardsToken) public view returns (uint256 amount) {
        return _balances[account].mul(
            rewardPerToken(_rewardsToken).sub(accountRewardPerTokenPaid[account][_rewardsToken])
        ).div(1e18).add(rewards[account][_rewardsToken]);
    }

    /// @notice Helper function for assessing distribution timelines.
    /// @param _rewardsToken The asset that's being distributed.
    /// @return timestamp The most recent time (in UNIX format) at which rewards are available for distribution.
    function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint256 timestamp) {
        return Math.min(block.timestamp, rewardData[_rewardsToken].periodFinish);
    }

    /// @notice Cumulative amount of rewards distributed per LP token.
    /// @param _rewardsToken The asset that's being distributed.
    /// @return amount The cumulative amount of rewards distributed per LP token.
    function rewardPerToken(address _rewardsToken) public view returns (uint256 amount) {
        if (_totalSupply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return rewardData[_rewardsToken].rewardPerTokenStored.add(
            lastTimeRewardApplicable(_rewardsToken).sub(
                rewardData[_rewardsToken].lastUpdateTime
            ).mul(rewardData[_rewardsToken].rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    /// @notice Adds a new asset as a reward to this contract.
    /// @param _rewardsToken The asset that's being distributed.
    /// @param _rewardsDuration How long rewards take to vest, e.g. 30 days (denoted in seconds).
    function addReward(address _rewardsToken, uint256 _rewardsDuration) external onlyOwner {
        require(_rewardsDuration > 0, "ZivoeRewards::addReward() _rewardsDuration == 0");
        require(rewardData[_rewardsToken].rewardsDuration == 0, "ZivoeRewards::addReward() rewardData[_rewardsToken].rewardsDuration != 0");
        require(rewardTokens.length < 10, "ZivoeRewards::addReward() rewardTokens.length >= 10");

        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
        emit RewardAdded(_rewardsToken);
    }

    /// @notice Deposits a reward to this contract for distribution.
    /// @param _rewardsToken The asset that's being distributed.
    /// @param reward The amount of the _rewardsToken to deposit.
    function depositReward(address _rewardsToken, uint256 reward) external updateReward(address(0)) nonReentrant {
        IERC20(_rewardsToken).safeTransferFrom(_msgSender(), address(this), reward);

        // Update vesting accounting for reward (if existing rewards being distributed, increase proportionally).
        if (block.timestamp >= rewardData[_rewardsToken].periodFinish) {
            rewardData[_rewardsToken].rewardRate = reward.div(rewardData[_rewardsToken].rewardsDuration);
        } else {
            uint256 remaining = rewardData[_rewardsToken].periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardData[_rewardsToken].rewardRate);
            rewardData[_rewardsToken].rewardRate = reward.add(leftover).div(rewardData[_rewardsToken].rewardsDuration);
        }

        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp.add(rewardData[_rewardsToken].rewardsDuration);
        emit RewardDeposited(_rewardsToken, reward, _msgSender());
    }

    /// @notice Simultaneously calls withdraw() and getRewards() for convenience.
    function fullWithdraw() external {
        withdraw(_balances[_msgSender()]);
        getRewards();
    }

    /// @notice Stakes the specified amount of stakingToken to this contract.
    /// @param amount The amount of the _rewardsToken to deposit.
    function stake(uint256 amount) external nonReentrant updateReward(_msgSender()) {
        require(amount > 0, "ZivoeRewards::stake() amount == 0");

        _totalSupply = _totalSupply.add(amount);
        _balances[_msgSender()] = _balances[_msgSender()].add(amount);
        stakingToken.safeTransferFrom(_msgSender(), address(this), amount);
        emit Staked(_msgSender(), amount);
    }
    
    /// @notice Claim rewards for all possible _rewardTokens.
    function getRewards() public updateReward(_msgSender()) {
        for (uint256 i = 0; i < rewardTokens.length; i++) { getRewardAt(i); }
    }
    
    /// @notice Claim rewards for a specific _rewardToken.
    /// @param index The index to claim, corresponds to a given index of rewardToken[].
    function getRewardAt(uint256 index) public nonReentrant updateReward(_msgSender()) {
        address _rewardsToken = rewardTokens[index];
        uint256 reward = rewards[_msgSender()][_rewardsToken];
        if (reward > 0) {
            rewards[_msgSender()][_rewardsToken] = 0;
            IERC20(_rewardsToken).safeTransfer(_msgSender(), reward);
            emit RewardDistributed(_msgSender(), _rewardsToken, reward);
        }
    }

    /// @notice Withdraws the specified amount of stakingToken from this contract.
    /// @param amount The amount of the _rewardsToken to withdraw.
    function withdraw(uint256 amount) public nonReentrant updateReward(_msgSender()) {
        require(amount > 0, "ZivoeRewards::withdraw() amount == 0");

        _totalSupply = _totalSupply.sub(amount);
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
        stakingToken.safeTransfer(_msgSender(), amount);
        emit Withdrawn(_msgSender(), amount);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "./libraries/ZivoeOwnableLocked.sol";

interface ZivoeRewardsVesting_IZivoeGlobals {
    /// @notice Returns the address of the ZivoeToken.sol contract.
    function ZVE() external view returns (address);
}

/// @notice  This contract facilitates staking and yield distribution, as well as vesting tokens.
///          This contract has the following responsibilities:
///            - Allows creation of vesting schedules (and revocation) for "vestingToken".
///            - Allows unstaking of vested tokens.
///            - Allows claiming yield distributed / "deposited" to this contract.
///            - Allows multiple assets to be added as "rewardToken" for distributions (except for "vestingToken").
///            - Vests rewardTokens linearly overtime to stakers.
contract ZivoeRewardsVesting is ReentrancyGuard, ZivoeOwnableLocked {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    struct Reward {
        uint256 rewardsDuration;        /// @dev How long rewards take to vest, e.g. 30 days.
        uint256 periodFinish;           /// @dev When current rewards will finish vesting.
        uint256 rewardRate;             /// @dev Rewards emitted per second.
        uint256 lastUpdateTime;         /// @dev Last time this data struct was updated.
        uint256 rewardPerTokenStored;   /// @dev Last snapshot of rewardPerToken taken.
    }

    struct VestingSchedule {
        uint256 startingUnix;       /// @dev The block.timestamp at which tokens will start vesting.
        uint256 cliffUnix;          /// @dev The block.timestamp at which tokens are first claimable.
        uint256 endingUnix;         /// @dev The block.timestamp at which tokens will stop vesting (finished).
        uint256 totalVesting;       /// @dev The total amount to vest.
        uint256 totalWithdrawn;     /// @dev The total amount withdrawn so far.
        uint256 vestingPerSecond;   /// @dev The amount of vestingToken that vests per second.
        bool revokable;             /// @dev Whether or not this vesting schedule can be revoked.
    }
    
    address public immutable GBL;       /// @dev The ZivoeGlobals contract.

    address public vestingToken;        /// @dev The token vesting, in this case Zivoe ($ZVE).

    address[] public rewardTokens;      /// @dev Array of ERC20 tokens distributed as rewards (if present).
    
    uint256 public vestingTokenAllocated;   /// @dev The amount of vestingToken currently allocated.

    uint256 private _totalSupply;       /// @dev Total supply of (non-transferrable) LP tokens for reards contract.

    IERC20 public stakingToken;         /// @dev IERC20 wrapper for the stakingToken (deposited to receive LP tokens).

    mapping(address => bool) public vestingScheduleSet; /// Tracks if a wallet has been assigned a schedule.

    mapping(address => VestingSchedule) public vestingScheduleOf;  /// Tracks the vesting schedule of accounts.

    mapping(address => Reward) public rewardData;   /// @dev Contains rewards information for each rewardToken.

    mapping(address => uint256) private _balances;  /// @dev Contains LP token balance of each account (is 1:1 ratio with amount deposited).

    mapping(address => mapping(address => uint256)) public rewards;                 /// @dev The order is account -> rewardAsset -> amount.
    mapping(address => mapping(address => uint256)) public accountRewardPerTokenPaid;  /// @dev The order is account -> rewardAsset -> amount.

    

    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeRewards.sol contract.
    /// @param _stakingToken The ERC20 asset deposited to mint LP tokens (and returned when burning LP tokens).
    /// @param _GBL The ZivoeGlobals contract.
    constructor(
        address _stakingToken,
        address _GBL
    ) {
        stakingToken = IERC20(_stakingToken);
        vestingToken = _stakingToken;
        GBL = _GBL;
    }



    // ------------
    //    Events
    // ------------

    /// @notice Emitted during addReward().
    /// @param  reward The asset now supported as a reward.
    event RewardAdded(address indexed reward);

    /// @notice Emitted during depositReward().
    /// @param  reward The asset that's being deposited.
    /// @param  amount The amout deposited.
    /// @param  depositor The _msgSender() who deposited said reward.
    event RewardDeposited(address indexed reward, uint256 amount, address indexed depositor);

    /// @notice Emitted during stake().
    /// @param  account The account staking "stakingToken".
    /// @param  amount The amount of  "stakingToken" staked.
    event Staked(address indexed account, uint256 amount);

    /// @notice Emitted during withdraw().
    /// @param  account The account withdrawing "stakingToken".
    /// @param  amount The amount of "stakingToken" withdrawn.
    event Withdrawn(address indexed account, uint256 amount);

    /// @notice Emitted during getRewardAt().
    /// @param  account The account receiving a reward.
    /// @param  rewardsToken The ERC20 asset distributed as a reward.
    /// @param  reward The amount of "rewardsToken" distributed.
    event RewardDistributed(address indexed account, address indexed rewardsToken, uint256 reward);

    /// @notice Emitted during vest().
    /// @param  account The account that was given a vesting schedule.
    /// @return startingUnix The block.timestamp at which tokens will start vesting.
    /// @return cliffUnix The block.timestamp at which tokens are first claimable.
    /// @return endingUnix The block.timestamp at which tokens will stop vesting (finished).
    /// @return totalVesting The total amount to vest.
    /// @return vestingPerSecond The amount of vestingToken that vests per second.
    /// @return revokable Whether or not this vesting schedule can be revoked.
    event VestingScheduleAdded(
        address indexed account,
        uint256 startingUnix,
        uint256 cliffUnix,
        uint256 endingUnix,
        uint256 totalVesting,
        uint256 vestingPerSecond,
        bool revokable
    );

    /// @notice Emitted during revoke().
    /// @param  account The account that was revoked a vesting schedule.
    /// @param  amountRevoked The amount of tokens revoked.
    /// @return cliffUnix The updated value for cliffUnix.
    /// @return endingUnix The updated value for endingUnix.
    /// @return totalVesting The total amount vested (claimable).
    /// @return revokable The final revokable status of schedule (always false after revocation).
    event VestingScheduleRevoked(
        address indexed account, 
        uint256 amountRevoked,
        uint256 cliffUnix,
        uint256 endingUnix,
        uint256 totalVesting,
        bool revokable
    );



    // ---------------
    //    Modifiers
    // ---------------

    /// @notice This modifier ensures account rewards information is updated BEFORE mutative actions.
    /// @param account The account to update personal rewards information of (if not address(0)).
    modifier updateReward(address account) {
        for (uint256 i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = rewardPerToken(token);
            rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(0)) {
                rewards[account][token] = earned(account, token);
                accountRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
        _;
    }



    // ---------------
    //    Functions
    // ---------------

    /// @notice Returns the amount of tokens owned by "account", received when depositing via stake().
    /// @param account The account to view information of.
    /// @return amount The amount of tokens owned by "account".
    function balanceOf(address account) external view returns (uint256 amount) {
        return _balances[account];
    }

    /// @notice Returns the amount of tokens in existence; these are minted and burned when depositing or withdrawing.
    /// @return amount The amount of tokens in existence.
    function totalSupply() external view returns (uint256 amount) {
        return _totalSupply;
    }

    /// @notice Returns the rewards earned of a specific rewardToken for an address.
    /// @param account The account to view information of.
    /// @param rewardAsset The asset earned as a reward.
    /// @return amount The amount of rewards earned.
    function viewRewards(address account, address rewardAsset) external view returns (uint256 amount) {
        return rewards[account][rewardAsset];
    }

    /// @notice Returns the last snapshot of rewardPerTokenStored taken for a reward asset.
    /// @param account The account to view information of.
    /// @param rewardAsset The reward token for which we want to return the rewardPerTokenstored.
    /// @return amount The latest up-to-date value of rewardPerTokenStored.
    function viewAccountRewardPerTokenPaid(address account, address rewardAsset) external view returns (uint256 amount) {
        return accountRewardPerTokenPaid[account][rewardAsset];
    }

    /// @notice Returns the total amount of rewards being distributed to everyone for current rewardsDuration.
    /// @param  _rewardsToken The asset that's being distributed.
    /// @return amount The amount of rewards being distributed.
    function getRewardForDuration(address _rewardsToken) external view returns (uint256 amount) {
        return rewardData[_rewardsToken].rewardRate.mul(rewardData[_rewardsToken].rewardsDuration);
    }

    /// @notice Returns the amount of $ZVE tokens an account can withdraw.
    /// @param  account The account to be withdrawn from.
    /// @return amount Withdrawable amount of $ZVE tokens.
    function amountWithdrawable(address account) public view returns (uint256 amount) {
        if (block.timestamp < vestingScheduleOf[account].cliffUnix) {
            return 0;
        }
        if (block.timestamp >= vestingScheduleOf[account].cliffUnix && block.timestamp < vestingScheduleOf[account].endingUnix) {
            return (
                vestingScheduleOf[account].vestingPerSecond * (block.timestamp - vestingScheduleOf[account].startingUnix)
            ) - vestingScheduleOf[account].totalWithdrawn;
        }
        else if (block.timestamp >= vestingScheduleOf[account].endingUnix) {
            return vestingScheduleOf[account].totalVesting - vestingScheduleOf[account].totalWithdrawn;
        }
        else {
            return 0;
        }
    }

    /// @notice Provides information on the rewards available for claim.
    /// @param account The account to view information of.
    /// @param _rewardsToken The asset that's being distributed.
    /// @return amount The amount of rewards earned.
    function earned(address account, address _rewardsToken) public view returns (uint256 amount) {
        return _balances[account].mul(
            rewardPerToken(_rewardsToken).sub(accountRewardPerTokenPaid[account][_rewardsToken])
        ).div(1e18).add(rewards[account][_rewardsToken]);
    }

    /// @notice Helper function for assessing distribution timelines.
    /// @param _rewardsToken The asset that's being distributed.
    /// @return timestamp The most recent time (in UNIX format) at which rewards are available for distribution.
    function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint256 timestamp) {
        return Math.min(block.timestamp, rewardData[_rewardsToken].periodFinish);
    }

    /// @notice Cumulative amount of rewards distributed per LP token.
    /// @param _rewardsToken The asset that's being distributed.
    /// @return amount The cumulative amount of rewards distributed per LP token.
    function rewardPerToken(address _rewardsToken) public view returns (uint256 amount) {
        if (_totalSupply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return rewardData[_rewardsToken].rewardPerTokenStored.add(
            lastTimeRewardApplicable(_rewardsToken).sub(
                rewardData[_rewardsToken].lastUpdateTime
            ).mul(rewardData[_rewardsToken].rewardRate).mul(1e18).div(_totalSupply)
        );
    }
    
    /// @notice Provides information for a vesting schedule.
    /// @param  account The account to view information of.
    /// @return startingUnix The block.timestamp at which tokens will start vesting.
    /// @return cliffUnix The block.timestamp at which tokens are first claimable.
    /// @return endingUnix The block.timestamp at which tokens will stop vesting (finished).
    /// @return totalVesting The total amount to vest.
    /// @return totalWithdrawn The total amount withdrawn so far.
    /// @return vestingPerSecond The amount of vestingToken that vests per second.
    /// @return revokable Whether or not this vesting schedule can be revoked.
    function viewSchedule(address account) external view returns (
        uint256 startingUnix, 
        uint256 cliffUnix, 
        uint256 endingUnix, 
        uint256 totalVesting, 
        uint256 totalWithdrawn, 
        uint256 vestingPerSecond, 
        bool revokable
    ) {
        startingUnix = vestingScheduleOf[account].startingUnix;
        cliffUnix = vestingScheduleOf[account].cliffUnix;
        endingUnix = vestingScheduleOf[account].endingUnix;
        totalVesting = vestingScheduleOf[account].totalVesting;
        totalWithdrawn = vestingScheduleOf[account].totalWithdrawn;
        vestingPerSecond = vestingScheduleOf[account].vestingPerSecond;
        revokable = vestingScheduleOf[account].revokable;
    }

    /// @notice Adds a new asset as a reward to this contract.
    /// @param _rewardsToken The asset that's being distributed.
    /// @param _rewardsDuration How long rewards take to vest, e.g. 30 days (denoted in seconds).
    function addReward(address _rewardsToken, uint256 _rewardsDuration) external onlyOwner {
        require(_rewardsToken != ZivoeRewardsVesting_IZivoeGlobals(GBL).ZVE(), "ZivoeRewardsVesting::addReward() _rewardsToken == ZivoeRewardsVesting_IZivoeGlobals(GBL).ZVE()");
        require(_rewardsDuration > 0, "ZivoeRewardsVesting::addReward() _rewardsDuration == 0");
        require(rewardData[_rewardsToken].rewardsDuration == 0, "ZivoeRewardsVesting::addReward() rewardData[_rewardsToken].rewardsDuration != 0");
        require(rewardTokens.length < 10, "ZivoeRewardsVesting::addReward() rewardTokens.length >= 10");

        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
        emit RewardAdded(_rewardsToken);
    }

    /// @notice Deposits a reward to this contract for distribution.
    /// @param _rewardsToken The asset that's being distributed.
    /// @param reward The amount of the _rewardsToken to deposit.
    function depositReward(address _rewardsToken, uint256 reward) external updateReward(address(0)) nonReentrant {
        IERC20(_rewardsToken).safeTransferFrom(_msgSender(), address(this), reward);

        // Update vesting accounting for reward (if existing rewards being distributed, increase proportionally).
        if (block.timestamp >= rewardData[_rewardsToken].periodFinish) {
            rewardData[_rewardsToken].rewardRate = reward.div(rewardData[_rewardsToken].rewardsDuration);
        } else {
            uint256 remaining = rewardData[_rewardsToken].periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardData[_rewardsToken].rewardRate);
            rewardData[_rewardsToken].rewardRate = reward.add(leftover).div(rewardData[_rewardsToken].rewardsDuration);
        }

        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp.add(rewardData[_rewardsToken].rewardsDuration);
        emit RewardDeposited(_rewardsToken, reward, _msgSender());
    }

    /// @notice Simultaneously calls withdraw() and getRewards() for convenience.
    function fullWithdraw() external {
        withdraw();
        getRewards();
    }

    /// @notice Sets the vestingSchedule for an account.
    /// @param  account The account vesting $ZVE.
    /// @param  daysToCliff The number of days before vesting is claimable (a.k.a. cliff period).
    /// @param  daysToVest The number of days for the entire vesting period, from beginning to end.
    /// @param  amountToVest The amount of tokens being vested.
    /// @param  revokable If the vested amount can be revoked.
    function vest(address account, uint256 daysToCliff, uint256 daysToVest, uint256 amountToVest, bool revokable) external onlyOwner {
        require(!vestingScheduleSet[account], "ZivoeRewardsVesting::vest() vestingScheduleSet[account]");
        require(
            IERC20(vestingToken).balanceOf(address(this)) - vestingTokenAllocated >= amountToVest, 
            "ZivoeRewardsVesting::vest() amountToVest > IERC20(vestingToken).balanceOf(address(this)) - vestingTokenAllocated"
        );
        require(daysToCliff <= daysToVest, "ZivoeRewardsVesting::vest() daysToCliff > daysToVest");

        vestingScheduleSet[account] = true;
        vestingTokenAllocated += amountToVest;
        
        vestingScheduleOf[account].startingUnix = block.timestamp;
        vestingScheduleOf[account].cliffUnix = block.timestamp + daysToCliff * 1 days;
        vestingScheduleOf[account].endingUnix = block.timestamp + daysToVest * 1 days;
        vestingScheduleOf[account].totalVesting = amountToVest;
        vestingScheduleOf[account].vestingPerSecond = amountToVest / (daysToVest * 1 days);
        vestingScheduleOf[account].revokable = revokable;
        
        emit VestingScheduleAdded(
            account, 
            vestingScheduleOf[account].startingUnix,
            vestingScheduleOf[account].cliffUnix,
            vestingScheduleOf[account].endingUnix,
            vestingScheduleOf[account].totalVesting,
            vestingScheduleOf[account].vestingPerSecond,
            vestingScheduleOf[account].revokable
        );

        _stake(amountToVest, account);
    }

    /// NOTE: Conduct further fuzz testing in addition to unit testing here.
    /// @notice Ends vesting schedule for a given account (if revokable).
    /// @param  account The acount to revoke a vesting schedule for.
    function revoke(address account) external updateReward(account) onlyOwner nonReentrant {
        require(vestingScheduleSet[account], "ZivoeRewardsVesting::revoke() !vestingScheduleSet[account]");
        require(vestingScheduleOf[account].revokable, "ZivoeRewardsVesting::revoke() !vestingScheduleOf[account].revokable");
        
        uint256 amount = amountWithdrawable(account);
        uint256 vestingAmount = vestingScheduleOf[account].totalVesting;

        vestingTokenAllocated -= amount;

        vestingScheduleOf[account].totalWithdrawn += amount;
        vestingScheduleOf[account].totalVesting = vestingScheduleOf[account].totalWithdrawn;
        vestingScheduleOf[account].cliffUnix = block.timestamp - 1;
        vestingScheduleOf[account].endingUnix = block.timestamp;

        vestingTokenAllocated -= (vestingAmount - vestingScheduleOf[account].totalWithdrawn);

        _totalSupply = _totalSupply.sub(vestingAmount);
        _balances[account] = 0;
        stakingToken.safeTransfer(account, amount);

        vestingScheduleOf[account].revokable = false;

        emit VestingScheduleRevoked(
            account, 
            vestingAmount - vestingScheduleOf[account].totalWithdrawn,
            vestingScheduleOf[account].cliffUnix,
            vestingScheduleOf[account].endingUnix,
            vestingScheduleOf[account].totalVesting,
            false
        );
    }

    /// @notice Stakes the specified amount of stakingToken to this contract.
    /// @dev Intended to be private, so only callable via vest().
    /// @param amount The amount of the _rewardsToken to deposit.
    /// @param account The account to stake for.
    function _stake(uint256 amount, address account) private nonReentrant updateReward(account) {
        require(amount > 0, "ZivoeRewardsVesting::_stake() amount == 0");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Staked(account, amount);
    }

    /// @notice Claim rewards for all possible _rewardTokens.
    function getRewards() public updateReward(_msgSender()) {
        for (uint256 i = 0; i < rewardTokens.length; i++) { getRewardAt(i); }
    }
    
    /// @notice Claim rewards for a specific _rewardToken.
    /// @param index The index to claim, corresponds to a given index of rewardToken[].
    function getRewardAt(uint256 index) public nonReentrant updateReward(_msgSender()) {
        address _rewardsToken = rewardTokens[index];
        uint256 reward = rewards[_msgSender()][_rewardsToken];
        if (reward > 0) {
            rewards[_msgSender()][_rewardsToken] = 0;
            IERC20(_rewardsToken).safeTransfer(_msgSender(), reward);
            emit RewardDistributed(_msgSender(), _rewardsToken, reward);
        }
    }

    /// @notice Withdraws the entire amount of stakingToken from this contract.
    function withdraw() public nonReentrant updateReward(_msgSender()) {
        uint256 amount = amountWithdrawable(_msgSender());
        require(amount > 0, "ZivoeRewardsVesting::withdraw() amountWithdrawable(_msgSender()) == 0");
        
        vestingScheduleOf[_msgSender()].totalWithdrawn += amount;
        vestingTokenAllocated -= amount;

        _totalSupply = _totalSupply.sub(amount);
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
        stakingToken.safeTransfer(_msgSender(), amount);

        emit Withdrawn(_msgSender(), amount);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./libraries/ZivoeERC20Votes.sol";

/// @notice  This ERC20 contract represents the ZivoeDAO governance token.
///          This contract should support the following functionalities:
///           - Burnable
contract ZivoeToken is ERC20Votes {

    // ---------------------
    //    State Variables
    // ---------------------

    address private _GBL;   /// @dev The ZivoeGlobals contract.



    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeToken.sol contract ($ZVE).
    /// @param name_ The name of $ZVE (Zivoe).
    /// @param symbol_ The symbol of $ZVE (ZVE).
    /// @param init The initial address to escrow $ZVE supply, prior to distribution.
    /// @param GBL_ The ZivoeGlobals contract.
    constructor(
        string memory name_,
        string memory symbol_,
        address init,
        address GBL_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        _GBL = GBL_;
        _mint(init, 25000000 ether);
    }



    // ---------------
    //    Functions
    // ---------------

    /// @notice Returns the address of the ZivoeGlobals contract.
    /// @return GBL_ The address of the ZivoeGlobals contract.
    function GBL() public view virtual override returns (address GBL_) {
        return _GBL;
    }

    /// @notice Burns $ZVE tokens.
    /// @param  amount The number of $ZVE tokens to burn.
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./ZivoeLocker.sol";

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

interface ZivoeTranches_IZivoeGlobals {
    /// @notice Returns the address of the ZivoeToken.sol contract.
    function ZVE() external view returns (address);

    /// @notice Returns the address of the ZivoeITO.sol contract.
    function ITO() external view returns (address);

    /// @notice Returns the address of the ZivoeDAO.sol contract.
    function DAO() external view returns (address);

    /// @notice Returns the address of the Zivoe Laboratory.
    function ZVL() external view returns (address);

    /// @notice Returns the address of the ZivoeTrancheToken.sol ($zSTT) contract.
    function zSTT() external view returns (address);

    /// @notice Returns the address of the ZivoeTrancheToken.sol ($zJTT) contract.
    function zJTT() external view returns (address);

    /// @notice Handles WEI standardization of a given asset amount (i.e. 6 decimal precision => 18 decimal precision).
    /// @param amount The amount of a given "asset".
    /// @param asset The asset (ERC-20) from which to standardize the amount to WEI.
    /// @return standardizedAmount The above amount standardized to 18 decimals.
    function standardize(uint256 amount, address asset) external view returns (uint256 standardizedAmount);

    /// @notice Returns total circulating supply of zSTT and zJTT, accounting for defaults via markdowns.
    /// @return zSTTSupply zSTT.totalSupply() adjusted for defaults.
    /// @return zJTTSupply zJTT.totalSupply() adjusted for defaults.
    function adjustedSupplies() external view returns (uint256 zSTTSupply, uint256 zJTTSupply);

    /// @notice Returns the "maxTrancheRatioBIPS" variable.
    /// @dev This ratio represents the maximum size allowed for junior tranche, relative to senior tranche.
    ///      A value of 2,000 represent 20%, thus junior tranche at maximum can be 20% the size of senior tranche.
    function maxTrancheRatioBIPS() external view returns (uint256);

    /// @notice This function will verify if a given stablecoin has been whitelisted for use throughout system (ZVE, YDL).
    /// @param stablecoin address of the stablecoin to verify acceptance for.
    /// @return whitelisted Will equal "true" if stabeloin is acceptable, and "false" if not.
    function stablecoinWhitelist(address stablecoin) external view returns (bool whitelisted);

    /// @notice Returns the "lowerRatioIncentive" variable.
    /// @return lowerRatioIncentive This value represents basis points ratio between 
    /// zJTT.totalSupply():zSTT.totalSupply() for maximum rewards.
    function lowerRatioIncentive() external view returns (uint256 lowerRatioIncentive);

    /// @notice Returns the "upperRatioIncentive" variable.
    /// @return upperRatioIncentive This value represents basis points ratio between
    /// zJTT.totalSupply():zSTT.totalSupply() for maximum rewards.
    function upperRatioIncentive() external view returns (uint256 upperRatioIncentive);

    /// @notice Returns the "minZVEPerJTTMint" variable.
    /// @return minZVEPerJTTMint This value controls the min $ZVE minted per stablecoin deposited to ZivoeTranches.sol.
    function minZVEPerJTTMint() external view returns (uint256 minZVEPerJTTMint);

    /// @notice Returns the "maxZVEPerJTTMint" variable.
    /// @return maxZVEPerJTTMint This value controls the max $ZVE minted per stablecoin deposited to ZivoeTranches.sol.
    function maxZVEPerJTTMint() external view returns (uint256 maxZVEPerJTTMint);
}

interface ZivoeTranches_IERC20Mintable {
    /// @notice Creates ERC20 tokens and assigns them to an address, increasing the total supply.
    /// @param account The address to send the newly created tokens to.
    /// @param amount The amount of tokens to create and send.
    function mint(address account, uint256 amount) external;
}

/// @notice  This contract will facilitate ongoing liquidity provision to Zivoe tranches - Junior, Senior.
///          This contract will be permissioned by $zJTT and $zSTT to call mint().
///          This contract will support a whitelist for stablecoins to provide as liquidity.
contract ZivoeTranches is ZivoeLocker, ReentrancyGuard {

    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    address public immutable GBL;   /// @dev The ZivoeGlobals contract.

    bool public tranchesUnlocked;   /// @dev Prevents contract from supporting functionality until unlocked.
    bool public paused;             /// @dev Temporary mechanism for pausing deposits.

    uint256 private constant BIPS = 10000;



    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeTranches.sol contract.
    /// @param _GBL The ZivoeGlobals contract.
    constructor(address _GBL) {
        GBL = _GBL;
    }



    // ------------
    //    Events
    // ------------

    /// @notice Emitted during depositJunior().
    /// @param  account The account depositing stablecoins to junior tranche.
    /// @param  asset The stablecoin deposited.
    /// @param  amount The amount of stablecoins deposited.
    /// @param  incentives The amount of incentives ($ZVE) distributed.
    event JuniorDeposit(address indexed account, address indexed asset, uint256 amount, uint256 incentives);

    /// @notice Emitted during depositSenior().
    /// @param  account The account depositing stablecoins to senior tranche.
    /// @param  asset The stablecoin deposited.
    /// @param  amount The amount of stablecoins deposited.
    /// @param  incentives The amount of incentives ($ZVE) distributed.
    event SeniorDeposit(address indexed account, address indexed asset, uint256 amount, uint256 incentives);



    // ---------------
    //    Functions
    // ---------------

    modifier notPaused() {
        require(!paused, "ZivoeTranches::whenPaused() notPaused");
        _;
    }


    // ---------------
    //    Functions
    // ---------------

    /// @notice Permission for owner to call pushToLocker().
    function canPush() public override pure returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLocker().
    function canPull() public override pure returns (bool) {
        return true;
    }

    /// @notice Permission for owner to call pullFromLockerPartial().
    function canPullPartial() public override pure returns (bool) {
        return true;
    }

    /// @notice This pulls capital from the DAO, does any necessary pre-conversions, and escrows ZVE for incentives.
    /// @param asset The asset to pull from the DAO.
    /// @param amount The amount of asset to pull from the DAO.
    /// @param  data Accompanying transaction data.
    function pushToLocker(address asset, uint256 amount, bytes calldata data) external override onlyOwner {
        require(asset == ZivoeTranches_IZivoeGlobals(GBL).ZVE(), "ZivoeTranches::pushToLocker() asset != ZivoeTranches_IZivoeGlobals(GBL).ZVE()");

        IERC20(asset).safeTransferFrom(owner(), address(this), amount);
    }

    /// @notice Checks if stablecoins deposits into the Junior Tranche are open.
    /// @param  amount The amount to deposit.
    /// @param  asset The asset (stablecoin) to deposit.
    /// @return open Will return "true" if the deposits into the Junior Tranche are open.
    function isJuniorOpen(uint256 amount, address asset) public view returns (bool open) {
        uint256 convertedAmount = ZivoeTranches_IZivoeGlobals(GBL).standardize(amount, asset);
        (uint256 seniorSupp, uint256 juniorSupp) = ZivoeTranches_IZivoeGlobals(GBL).adjustedSupplies();
        return convertedAmount + juniorSupp < seniorSupp * ZivoeTranches_IZivoeGlobals(GBL).maxTrancheRatioBIPS() / BIPS;
    }

    /// @notice Pauses or unpauses the contract, enabling or disabling depositJunior() and depositSenior().
    function switchPause() external {
        require(
            _msgSender() == ZivoeTranches_IZivoeGlobals(GBL).ZVL(), 
            "ZivoeTranches::switchPause() _msgSender() != ZivoeTranches_IZivoeGlobals(GBL).ZVL()"
        );
        paused = !paused;
    }

    /// @notice Deposit stablecoins into the junior tranche.
    /// @dev    Mints Zivoe Junior Tranche ($zJTT) tokens in 1:1 ratio.
    /// @param  amount The amount to deposit.
    /// @param  asset The asset (stablecoin) to deposit.
    function depositJunior(uint256 amount, address asset) external notPaused nonReentrant {
        require(ZivoeTranches_IZivoeGlobals(GBL).stablecoinWhitelist(asset), "ZivoeTranches::depositJunior() !ZivoeTranches_IZivoeGlobals(GBL).stablecoinWhitelist(asset)");
        require(tranchesUnlocked, "ZivoeTranches::depositJunior() !tranchesUnlocked");

        address depositor = _msgSender();

        IERC20(asset).safeTransferFrom(depositor, ZivoeTranches_IZivoeGlobals(GBL).DAO(), amount);
        
        uint256 convertedAmount = ZivoeTranches_IZivoeGlobals(GBL).standardize(amount, asset);

        require(isJuniorOpen(amount, asset),"ZivoeTranches::depositJunior() !isJuniorOpen(amount, asset)");

        uint256 incentives = rewardZVEJuniorDeposit(convertedAmount);
        emit JuniorDeposit(depositor, asset, amount, incentives);

        // NOTE: Ordering important, transfer ZVE rewards prior to minting zJTT() due to totalSupply() changes.
        IERC20(ZivoeTranches_IZivoeGlobals(GBL).ZVE()).safeTransfer(depositor, incentives);
        ZivoeTranches_IERC20Mintable(ZivoeTranches_IZivoeGlobals(GBL).zJTT()).mint(depositor, convertedAmount);
    }

    /// @notice Deposit stablecoins into the senior tranche.
    /// @dev    Mints Zivoe Senior Tranche ($zSTT) tokens in 1:1 ratio.
    /// @param  amount The amount to deposit.
    /// @param  asset The asset (stablecoin) to deposit.
    function depositSenior(uint256 amount, address asset) external notPaused nonReentrant {
        require(ZivoeTranches_IZivoeGlobals(GBL).stablecoinWhitelist(asset), "ZivoeTranches::depositSenior() !ZivoeTranches_IZivoeGlobals(GBL).stablecoinWhitelist(asset)");
        require(tranchesUnlocked, "ZivoeTranches::depositSenior() !tranchesUnlocked");

        address depositor = _msgSender();

        IERC20(asset).safeTransferFrom(depositor, ZivoeTranches_IZivoeGlobals(GBL).DAO(), amount);
        
        uint256 convertedAmount = ZivoeTranches_IZivoeGlobals(GBL).standardize(amount, asset);

        uint256 incentives = rewardZVESeniorDeposit(convertedAmount);

        emit SeniorDeposit(depositor, asset, amount, incentives);

        // NOTE: Ordering important, transfer ZVE rewards prior to minting zJTT() due to totalSupply() changes.
        IERC20(ZivoeTranches_IZivoeGlobals(GBL).ZVE()).safeTransfer(depositor, incentives);
        ZivoeTranches_IERC20Mintable(ZivoeTranches_IZivoeGlobals(GBL).zSTT()).mint(depositor, convertedAmount);
    }

    /// @notice Returns the total rewards in $ZVE for a certain junior tranche deposit amount.
    /// @dev Input amount MUST be in WEI (use GBL.standardize(amount, asset)).
    /// @dev Output amount MUST be in WEI.
    /// @param deposit The amount supplied to the junior tranche.
    /// @return reward The rewards in $ZVE to be received.
    function rewardZVEJuniorDeposit(uint256 deposit) public view returns(uint256 reward) {

        (uint256 seniorSupp, uint256 juniorSupp) = ZivoeTranches_IZivoeGlobals(GBL).adjustedSupplies();

        uint256 avgRate;    // The avg ZVE per stablecoin deposit reward, used for reward calculation.

        uint256 diffRate = ZivoeTranches_IZivoeGlobals(GBL).maxZVEPerJTTMint() - ZivoeTranches_IZivoeGlobals(GBL).minZVEPerJTTMint();

        uint256 startRatio = juniorSupp * BIPS / seniorSupp;
        uint256 finalRatio = (juniorSupp + deposit) * BIPS / seniorSupp;
        uint256 avgRatio = (startRatio + finalRatio) / 2;

        if (avgRatio <= ZivoeTranches_IZivoeGlobals(GBL).lowerRatioIncentive()) {
            // Handle max case (Junior:Senior is 10% or less).
            avgRate = ZivoeTranches_IZivoeGlobals(GBL).maxZVEPerJTTMint();
        } else if (avgRatio >= ZivoeTranches_IZivoeGlobals(GBL).upperRatioIncentive()) {
            // Handle min case (Junior:Senior is 25% or more).
            avgRate = ZivoeTranches_IZivoeGlobals(GBL).minZVEPerJTTMint();
        } else {
            // Handle in-between case, avgRatio domain = (1000, 2500).
            avgRate = ZivoeTranches_IZivoeGlobals(GBL).maxZVEPerJTTMint() - diffRate * (avgRatio - 1000) / (1500);
        }

        reward = avgRate * deposit / 1 ether;

        // Reduce if ZVE balance < reward.
        if (IERC20(ZivoeTranches_IZivoeGlobals(GBL).ZVE()).balanceOf(address(this)) < reward) {
            reward = IERC20(ZivoeTranches_IZivoeGlobals(GBL).ZVE()).balanceOf(address(this));
        }
    }

    /// @notice Returns the total rewards in $ZVE for a certain senior tranche deposit amount.
    /// @dev Input amount MUST be in WEI (use GBL.standardize(amount, asset)).
    /// @dev Output amount MUST be in WEI.
    /// @param deposit The amount supplied to the senior tranche.
    /// @return reward The rewards in $ZVE to be received.
    function rewardZVESeniorDeposit(uint256 deposit) public view returns(uint256 reward) {

        (uint256 seniorSupp, uint256 juniorSupp) = ZivoeTranches_IZivoeGlobals(GBL).adjustedSupplies();

        uint256 avgRate;    // The avg ZVE per stablecoin deposit reward, used for reward calculation.

        uint256 diffRate = ZivoeTranches_IZivoeGlobals(GBL).maxZVEPerJTTMint() - ZivoeTranches_IZivoeGlobals(GBL).minZVEPerJTTMint();

        uint256 startRatio = juniorSupp * BIPS / seniorSupp;
        uint256 finalRatio = juniorSupp * BIPS / (seniorSupp + deposit);
        uint256 avgRatio = (startRatio + finalRatio) / 2;

        if (avgRatio <= ZivoeTranches_IZivoeGlobals(GBL).lowerRatioIncentive()) {
            // Handle max case (Junior:Senior is 10% or less).
            avgRate = ZivoeTranches_IZivoeGlobals(GBL).minZVEPerJTTMint();
        } else if (avgRatio >= ZivoeTranches_IZivoeGlobals(GBL).upperRatioIncentive()) {
            // Handle min case (Junior:Senior is 25% or more).
            avgRate = ZivoeTranches_IZivoeGlobals(GBL).maxZVEPerJTTMint();
        } else {
            // Handle in-between case, avgRatio domain = (1000, 2500).
            avgRate = ZivoeTranches_IZivoeGlobals(GBL).minZVEPerJTTMint() + diffRate * (avgRatio - 1000) / (1500);
        }

        reward = avgRate * deposit / 1 ether;

        // Reduce if ZVE balance < reward.
        if (IERC20(ZivoeTranches_IZivoeGlobals(GBL).ZVE()).balanceOf(address(this)) < reward) {
            reward = IERC20(ZivoeTranches_IZivoeGlobals(GBL).ZVE()).balanceOf(address(this));
        }
    }

    /// @notice Unlocks this contract for distributions, sets some initial variables.
    function unlock() external {
        require(_msgSender() == ZivoeTranches_IZivoeGlobals(GBL).ITO(), "ZivoeTranches::unlock() _msgSender() != ZivoeTranches_IZivoeGlobals(GBL).ITO()");
        
        tranchesUnlocked = true;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/// @notice  This ERC20 contract outlines the tranche token functionality.
///          This contract should support the following functionalities:
///           - Mintable
///           - Burnable
contract ZivoeTrancheToken is ERC20, Ownable {

    // ---------------------
    //    State Variables
    // ---------------------

    /// @dev Whitelist for accessibility to mint() function, exposed in isMinter() view function.
    mapping(address => bool) private _isMinter;



    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the TrancheToken.sol contract ($zTT).
    /// @dev    _totalSupply for this contract initializes to 0.
    /// @param name_ The name (Zivoe Junior Tranche, Zivoe Senior Tranche).
    /// @param symbol_ The symbol ($zJTT, $zSTT).
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) { }



    // ------------
    //    Events
    // ------------

    /// @notice This event is emitted when changeMinterRole() is called.
    /// @param  account The account who is receiving or losing the minter role.
    /// @param  allowed If true, the account is receiving minter role privlidges, if false the account is losing minter role privlidges.
    event MinterUpdated(address indexed account, bool allowed);



    // ---------------
    //    Modifiers
    // ---------------

    /// @dev Enforces the caller has minter role privlidges.
    modifier isMinterRole() {
        require(_isMinter[_msgSender()], "ZivoeTrancheToken::isMinterRole() !_isMinter[_msgSender()]");
        _;
    }



    // ---------------
    //    Functions
    // ---------------

    /// @notice Returns the whitelist status of account for accessibility to mint() function.
    /// @param account The account to inspect whitelist status.
    /// @return minter Returns true if account is allowed to access the mint() function.
    function isMinter(address account) external view returns (bool minter) {
        return _isMinter[account];
    }

    /// @notice Burns $zTT tokens.
    /// @param  amount The number of $zTT tokens to burn.
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /// @notice Update an account's permission for access to mint() function.
    /// @dev    Only callable by owner.
    /// @param  account The account to change permissions for.
    /// @param  allowed The permission to give account (true = permitted, false = prohibited).
    function changeMinterRole(address account, bool allowed) external onlyOwner {
        _isMinter[account] = allowed;
        emit MinterUpdated(account, allowed);
    }

    /// @notice Mints $zTT tokens.
    /// @dev    Only callable by accounts on the _isMinter whitelist.
    /// @param  account The account to mint tokens for.
    /// @param  amount The amount of $zTT tokens to mint for account.
    function mint(address account, uint256 amount) external isMinterRole {
        _mint(account, amount);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./libraries/ZivoeMath.sol";

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

interface YDL_IZivoeRewards {
    /// @notice Deposits a reward to this contract for distribution.
    /// @param _rewardsToken The asset that's being distributed.
    /// @param reward The amount of the _rewardsToken to deposit.
    function depositReward(address _rewardsToken, uint256 reward) external;
}

interface YDL_IZivoeGlobals {
    /// @notice Returns the address of the Timelock contract.
    function TLC() external view returns (address);

    /// @notice Returns the address of the ZivoeITO.sol contract.
    function ITO() external view returns (address);

    /// @notice Returns the address of the ZivoeDAO.sol contract.
    function DAO() external view returns (address);

    /// @notice Returns the address of the ZivoeTrancheToken.sol ($zSTT) contract.
    function zSTT() external view returns (address);

    /// @notice Returns the address of the ZivoeTrancheToken.sol ($zJTT) contract.
    function zJTT() external view returns (address);

    /// @notice Handles WEI standardization of a given asset amount (i.e. 6 decimal precision => 18 decimal precision).
    /// @param amount The amount of a given "asset".
    /// @param asset The asset (ERC-20) from which to standardize the amount to WEI.
    /// @return standardizedAmount The above amount standardized to 18 decimals.
    function standardize(uint256 amount, address asset) external view returns (uint256 standardizedAmount);

    /// @notice Returns total circulating supply of zSTT and zJTT, accounting for defaults via markdowns.
    /// @return zSTTSupply zSTT.totalSupply() adjusted for defaults.
    /// @return zJTTSupply zJTT.totalSupply() adjusted for defaults.
    function adjustedSupplies() external view returns (uint256 zSTTSupply, uint256 zJTTSupply);

    /// @notice This function will verify if a given stablecoin has been whitelisted for use throughout system (ZVE, YDL).
    /// @param stablecoin address of the stablecoin to verify acceptance for.
    /// @return whitelisted Will equal "true" if stabeloin is acceptable, and "false" if not.
    function stablecoinWhitelist(address stablecoin) external view returns (bool whitelisted);
    
    /// @notice Returns the address of the ZivoeRewards.sol ($zSTT) contract.
    function stSTT() external view returns (address);

    /// @notice Returns the address of the ZivoeRewards.sol ($zJTT) contract.
    function stJTT() external view returns (address);

    /// @notice Returns the address of the ZivoeRewards.sol ($ZVE) contract.
    function stZVE() external view returns (address);

    /// @notice Returns the address of the ZivoeRewardsVesting.sol ($ZVE) vesting contract.
    function vestZVE() external view returns (address);
}

/// @notice  This contract manages the accounting for distributing yield across multiple contracts.
///          This contract has the following responsibilities:
///            - Escrows yield in between distribution periods.
///            - Manages accounting for yield distribution.
///            - Supports modification of certain state variables for governance purposes.
///            - Tracks historical values using EMA (exponential moving average) on 30-day basis.
contract ZivoeYDL is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using ZivoeMath for uint256;

    // ---------------------
    //    State Variables
    // ---------------------

    struct Recipients {
        address[] recipients;
        uint256[] proportion;
    }

    Recipients protocolRecipients;          /// @dev Tracks the distributions for protocol earnings.
    Recipients residualRecipients;          /// @dev Tracks the distributions for residual earnings.

    address public immutable GBL;           /// @dev The ZivoeGlobals contract.

    address public distributedAsset;        /// @dev The "stablecoin" that will be distributed via YDL.
    
    bool public unlocked;                   /// @dev Prevents contract from supporting functionality until unlocked.

    // Weighted moving averages.
    uint256 public emaSTT;                  /// @dev Weighted moving average for senior tranche size, a.k.a. zSTT.totalSupply().
    uint256 public emaJTT;                  /// @dev Weighted moving average for junior tranche size, a.k.a. zJTT.totalSupply().
    uint256 public emaYield;                /// @dev Weighted moving average for yield distributions.

    // Indexing.
    uint256 public numDistributions;        /// @dev # of calls to distributeYield() starts at 0, computed on current index for moving averages.
    uint256 public lastDistribution;        /// @dev Used for timelock constraint to call distributeYield().

    // Accounting vars (governable).
    uint256 public targetAPYBIPS = 800;             /// @dev The target annualized yield for senior tranche.
    uint256 public targetRatioBIPS = 16250;         /// @dev The target ratio of junior to senior tranche.
    uint256 public protocolEarningsRateBIPS = 2000; /// @dev The protocol earnings rate.

    // Accounting vars (constant).
    uint256 public constant daysBetweenDistributions = 30;   /// @dev Number of days between yield distributions.
    uint256 public constant retrospectiveDistributions = 6;  /// @dev The # of distributions to track historical (weighted) performance.

    uint256 private constant BIPS = 10000;
    uint256 private constant WAD = 10 ** 18;
    uint256 private constant RAY = 10 ** 27;



    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initialize the ZivoeYDL.sol contract.
    /// @param _GBL The ZivoeGlobals contract.
    /// @param _distributedAsset The "stablecoin" that will be distributed via YDL.
    constructor(address _GBL, address _distributedAsset) {
        GBL = _GBL;
        distributedAsset = _distributedAsset;
    }



    // ------------
    //    Events
    // ------------

    /// @notice Emitted during recoverAsset().
    /// @param  asset The asset recovered from this contract (migrated to DAO).
    /// @param  amount The amount recovered.
    event AssetRecovered(address indexed asset, uint256 amount);

    /// @notice Emitted during setTargetAPYBIPS().
    /// @param  oldValue The old value of targetAPYBIPS.
    /// @param  newValue The new value of targetAPYBIPS.
    event UpdatedTargetAPYBIPS(uint256 oldValue, uint256 newValue);

    /// @notice Emitted during setTargetRatioBIPS().
    /// @param  oldValue The old value of targetRatioBIPS.
    /// @param  newValue The new value of targetRatioBIPS.
    event UpdatedTargetRatioBIPS(uint256 oldValue, uint256 newValue);

    /// @notice Emitted during setProtocolEarningsRateBIPS().
    /// @param  oldValue The old value of protocolEarningsRateBIPS.
    /// @param  newValue The new value of protocolEarningsRateBIPS.
    event UpdatedProtocolEarningsRateBIPS(uint256 oldValue, uint256 newValue);

    /// @notice Emitted during setDistributedAsset().
    /// @param  oldAsset The old asset of distributedAsset.
    /// @param  newAsset The new asset of distributedAsset.
    event UpdatedDistributedAsset(address indexed oldAsset, address indexed newAsset);

    /// @notice Emitted during updateProtocolRecipients().
    /// @param  recipients The new recipients to receive protocol earnings.
    /// @param  proportion The proportion distributed across recipients.
    event UpdatedProtocolRecipients(address[] recipients, uint256[] proportion);

    /// @notice Emitted during updateResidualRecipients().
    /// @param  recipients The new recipients to receive residual earnings.
    /// @param  proportion The proportion distributed across recipients.
    event UpdatedResidualRecipients(address[] recipients, uint256[] proportion);

    /// @notice Emitted during distributeYield().
    /// @param  protocol The amount of earnings distributed to protocol earnings recipients.
    /// @param  senior The amount of earnings distributed to the senior tranche.
    /// @param  junior The amount of earnings distributed to the junior tranche.
    /// @param  residual The amount of earnings distributed to residual earnings recipients.
    event YieldDistributed(uint256[] protocol, uint256 senior, uint256 junior, uint256[] residual);

    /// @notice Emitted during distributeYield().
    /// @param  asset The "asset" being distributed.
    /// @param  recipient The recipient of the distribution.
    /// @param  amount The amount distributed.
    event YieldDistributedSingle(address indexed asset, address indexed recipient, uint256 amount);

    /// @notice Emitted during supplementYield().
    /// @param  senior The amount of yield supplemented to the senior tranche.
    /// @param  junior The amount of yield supplemented to the junior tranche.
    event YieldSupplemented(uint256 senior, uint256 junior);



    // ---------------
    //    Functions
    // ---------------

    /// @notice Updates the state variable "targetAPYBIPS".
    /// @param _targetAPYBIPS The new value for targetAPYBIPS.
    function setTargetAPYBIPS(uint256 _targetAPYBIPS) external {
        require(_msgSender() == YDL_IZivoeGlobals(GBL).TLC(), "ZivoeYDL::setTargetAPYBIPS() _msgSender() != TLC()");

        emit UpdatedTargetAPYBIPS(targetAPYBIPS, _targetAPYBIPS);
        targetAPYBIPS = _targetAPYBIPS;
    }

    /// @notice Updates the state variable "targetRatioBIPS".
    /// @param _targetRatioBIPS The new value for targetRatioBIPS.
    function setTargetRatioBIPS(uint256 _targetRatioBIPS) external {
        require(_msgSender() == YDL_IZivoeGlobals(GBL).TLC(), "ZivoeYDL::setTargetRatioBIPS() _msgSender() != TLC()");

        emit UpdatedTargetRatioBIPS(targetRatioBIPS, _targetRatioBIPS);
        targetRatioBIPS = _targetRatioBIPS;
    }

    /// @notice Updates the state variable "protocolEarningsRateBIPS".
    /// @param _protocolEarningsRateBIPS The new value for protocolEarningsRateBIPS.
    function setProtocolEarningsRateBIPS(uint256 _protocolEarningsRateBIPS) external {
        require(_msgSender() == YDL_IZivoeGlobals(GBL).TLC(), "ZivoeYDL::setProtocolEarningsRateBIPS() _msgSender() != TLC()");
        require(_protocolEarningsRateBIPS <= 3000, "ZivoeYDL::setProtocolEarningsRateBIPS() _protocolEarningsRateBIPS > 3000");

        emit UpdatedProtocolEarningsRateBIPS(protocolEarningsRateBIPS, _protocolEarningsRateBIPS);
        protocolEarningsRateBIPS = _protocolEarningsRateBIPS;
    }

    /// @notice Updates the distributed asset for this particular contract.
    /// @param _distributedAsset The new value for distributedAsset.
    function setDistributedAsset(address _distributedAsset) external nonReentrant {
        require(_distributedAsset != distributedAsset, "ZivoeYDL::setDistributedAsset() _distributedAsset == distributedAsset");
        require(_msgSender() == YDL_IZivoeGlobals(GBL).TLC(), "ZivoeYDL::setDistributedAsset() _msgSender() != TLC()");
        require(
            YDL_IZivoeGlobals(GBL).stablecoinWhitelist(_distributedAsset),
            "ZivoeYDL::setDistributedAsset() !YDL_IZivoeGlobals(GBL).stablecoinWhitelist(_distributedAsset)"
        );

        emit UpdatedDistributedAsset(distributedAsset, _distributedAsset);
        IERC20(distributedAsset).safeTransfer(YDL_IZivoeGlobals(GBL).DAO(), IERC20(distributedAsset).balanceOf(address(this)));
        distributedAsset = _distributedAsset;
    }

    /// @notice Recovers any extraneous ERC-20 asset held within this contract.
    /// @param asset The ERC20 asset to recoever.
    function recoverAsset(address asset) external {
        require(unlocked, "ZivoeYDL::recoverAsset() !unlocked");
        require(asset != distributedAsset, "ZivoeYDL::recoverAsset() asset == distributedAsset");

        emit AssetRecovered(asset, IERC20(asset).balanceOf(address(this)));
        IERC20(asset).safeTransfer(YDL_IZivoeGlobals(GBL).DAO(), IERC20(asset).balanceOf(address(this)));
    }

    /// @notice Unlocks this contract for distributions, initializes values.
    function unlock() external {
        require(_msgSender() == YDL_IZivoeGlobals(GBL).ITO(), "ZivoeYDL::unlock() _msgSender() != YDL_IZivoeGlobals(GBL).ITO()");

        unlocked = true;
        lastDistribution = block.timestamp;

        emaSTT = IERC20(YDL_IZivoeGlobals(GBL).zSTT()).totalSupply();
        emaJTT = IERC20(YDL_IZivoeGlobals(GBL).zJTT()).totalSupply();

        address[] memory protocolRecipientAcc = new address[](2);
        uint256[] memory protocolRecipientAmt = new uint256[](2);

        protocolRecipientAcc[0] = address(YDL_IZivoeGlobals(GBL).DAO());
        protocolRecipientAmt[0] = 7500;
        protocolRecipientAcc[1] = address(YDL_IZivoeGlobals(GBL).stZVE());
        protocolRecipientAmt[1] = 2500;

        protocolRecipients = Recipients(protocolRecipientAcc, protocolRecipientAmt);

        address[] memory residualRecipientAcc = new address[](4);
        uint256[] memory residualRecipientAmt = new uint256[](4);

        residualRecipientAcc[0] = address(YDL_IZivoeGlobals(GBL).stJTT());
        residualRecipientAmt[0] = 2500;
        residualRecipientAcc[1] = address(YDL_IZivoeGlobals(GBL).stSTT());
        residualRecipientAmt[1] = 2500;
        residualRecipientAcc[2] = address(YDL_IZivoeGlobals(GBL).stZVE());
        residualRecipientAmt[2] = 2500;
        residualRecipientAcc[3] = address(YDL_IZivoeGlobals(GBL).DAO());
        residualRecipientAmt[3] = 2500;

        residualRecipients = Recipients(residualRecipientAcc, residualRecipientAmt);
    }

    /// @notice Updates the protocolRecipients state variable which tracks the distributions for protocol earnings.
    /// @param recipients An array of addresses to which protocol earnings will be distributed.
    /// @param proportions An array of ratios relative to the recipients - in BIPS. Sum should equal to 10000.
    function updateProtocolRecipients(address[] memory recipients, uint256[] memory proportions) external {
        require(_msgSender() == YDL_IZivoeGlobals(GBL).TLC(), "ZivoeYDL::updateProtocolRecipients() _msgSender() != TLC()");
        require(
            recipients.length == proportions.length && recipients.length > 0, 
            "ZivoeYDL::updateProtocolRecipients() recipients.length != proportions.length || recipients.length == 0"
        );
        require(unlocked, "ZivoeYDL::updateProtocolRecipients() !unlocked");

        uint256 proportionTotal;
        for (uint256 i = 0; i < recipients.length; i++) {
            proportionTotal += proportions[i];
            require(proportions[i] > 0, "ZivoeYDL::updateProtocolRecipients() proportions[i] == 0");
        }

        require(proportionTotal == BIPS, "ZivoeYDL::updateProtocolRecipients() proportionTotal != BIPS (10,000)");

        emit UpdatedProtocolRecipients(recipients, proportions);
        protocolRecipients = Recipients(recipients, proportions);
    }

    /// @notice Updates the residualRecipients state variable which tracks the distribution for residual earnings.
    /// @param recipients An array of addresses to which residual earnings will be distributed.
    /// @param proportions An array of ratios relative to the recipients - in BIPS. Sum should equal to 10000.
    function updateResidualRecipients(address[] memory recipients, uint256[] memory proportions) external {
        require(_msgSender() == YDL_IZivoeGlobals(GBL).TLC(), "ZivoeYDL::updateResidualRecipients() _msgSender() != TLC()");
        require(
            recipients.length == proportions.length && recipients.length > 0, 
            "ZivoeYDL::updateResidualRecipients() recipients.length != proportions.length || recipients.length == 0"
        );
        require(unlocked, "ZivoeYDL::updateResidualRecipients() !unlocked");

        uint256 proportionTotal;
        for (uint256 i = 0; i < recipients.length; i++) {
            proportionTotal += proportions[i];
            require(proportions[i] > 0, "ZivoeYDL::updateResidualRecipients() proportions[i] == 0");
        }

        require(proportionTotal == BIPS, "ZivoeYDL::updateResidualRecipients() proportionTotal != BIPS (10,000)");

        emit UpdatedResidualRecipients(recipients, proportions);
        residualRecipients = Recipients(recipients, proportions);
    }

    /// @notice Will return the split of ongoing protocol earnings for a given senior and junior tranche size.
    /// @param seniorTrancheSize The value of the senior tranche.
    /// @param juniorTrancheSize The value of the junior tranche.
    /// @return protocol Protocol earnings.
    /// @return senior Senior tranche earnings.
    /// @return junior Junior tranche earnings.
    /// @return residual Residual earnings.
    function earningsTrancheuse(
        uint256 seniorTrancheSize, 
        uint256 juniorTrancheSize
    ) public view returns (
        uint256[] memory protocol, 
        uint256 senior,
        uint256 junior,
        uint256[] memory residual
    ) {

        uint256 earnings = IERC20(distributedAsset).balanceOf(address(this));

        // Handle accounting for protocol earnings.
        protocol = new uint256[](protocolRecipients.recipients.length);
        uint256 protocolEarnings = protocolEarningsRateBIPS * earnings / BIPS;
        for (uint256 i = 0; i < protocolRecipients.recipients.length; i++) {
            protocol[i] = protocolRecipients.proportion[i] * protocolEarnings / BIPS;
        }

        earnings = earnings.zSub(protocolEarnings);

        uint256 _seniorRate = rateSenior_RAY(
            YDL_IZivoeGlobals(GBL).standardize(earnings, distributedAsset),
            seniorTrancheSize,
            juniorTrancheSize,
            targetAPYBIPS,
            targetRatioBIPS,
            daysBetweenDistributions,
            retrospectiveDistributions
        );
        
        uint256 _juniorRate = rateJunior_RAY(
            seniorTrancheSize,
            juniorTrancheSize,
            _seniorRate,
            targetRatioBIPS
        );

        senior = (earnings * _seniorRate) / RAY;
        junior = (earnings * _juniorRate) / RAY;
        
        // Handle accounting for residual earnings.
        residual = new uint256[](residualRecipients.recipients.length);
        uint256 residualEarnings = earnings.zSub(senior + junior);
        for (uint256 i = 0; i < residualRecipients.recipients.length; i++) {
            residual[i] = residualRecipients.proportion[i] * residualEarnings / BIPS;
        }

    }

    /// @notice Distributes available yield within this contract to appropriate entities.
    function distributeYield() external nonReentrant {
        require(unlocked, "ZivoeYDL::distributeYield() !unlocked"); 
        require(
            block.timestamp >= lastDistribution + daysBetweenDistributions * 86400, 
            "ZivoeYDL::distributeYield() block.timestamp < lastDistribution + daysBetweenDistributions * 86400"
        );

        (uint256 seniorSupp, uint256 juniorSupp) = YDL_IZivoeGlobals(GBL).adjustedSupplies();

        (
            uint256[] memory _protocol,
            uint256 _seniorTranche,
            uint256 _juniorTranche,
            uint256[] memory _residual
        ) = earningsTrancheuse(seniorSupp, juniorSupp);

        emit YieldDistributed(_protocol, _seniorTranche, _juniorTranche, _residual);

        numDistributions += 1;

        lastDistribution = block.timestamp;
        
        if (emaYield == 0) {
            emaYield = IERC20(distributedAsset).balanceOf(address(this));
        }
        else {
            emaYield = ema(
                emaYield,
                YDL_IZivoeGlobals(GBL).standardize(_seniorTranche, distributedAsset),
                retrospectiveDistributions,
                numDistributions
            );
        }
        
        emaJTT = ema(
            emaJTT,
            juniorSupp,
            retrospectiveDistributions,
            numDistributions
        );

        emaSTT = ema(
            emaSTT,
            seniorSupp,
            retrospectiveDistributions,
            numDistributions
        );

        // Distribute protocol earnings.
        for (uint256 i = 0; i < protocolRecipients.recipients.length; i++) {
            address _recipient = protocolRecipients.recipients[i];
            if (_recipient == YDL_IZivoeGlobals(GBL).stSTT() ||_recipient == YDL_IZivoeGlobals(GBL).stJTT()) {
                IERC20(distributedAsset).safeApprove(_recipient, _protocol[i]);
                YDL_IZivoeRewards(_recipient).depositReward(distributedAsset, _protocol[i]);
                emit YieldDistributedSingle(distributedAsset, _recipient, _protocol[i]);
            }
            else if (_recipient == YDL_IZivoeGlobals(GBL).stZVE()) {
                uint256 splitBIPS = (
                    IERC20(YDL_IZivoeGlobals(GBL).stZVE()).totalSupply() * BIPS
                ) / (IERC20(YDL_IZivoeGlobals(GBL).stZVE()).totalSupply() + IERC20(YDL_IZivoeGlobals(GBL).vestZVE()).totalSupply());
                IERC20(distributedAsset).safeApprove(YDL_IZivoeGlobals(GBL).stZVE(), _protocol[i] * splitBIPS / BIPS);
                IERC20(distributedAsset).safeApprove(YDL_IZivoeGlobals(GBL).vestZVE(), _protocol[i] * (BIPS - splitBIPS) / BIPS);
                YDL_IZivoeRewards(YDL_IZivoeGlobals(GBL).stZVE()).depositReward(distributedAsset, _protocol[i] * splitBIPS / BIPS);
                YDL_IZivoeRewards(YDL_IZivoeGlobals(GBL).vestZVE()).depositReward(distributedAsset, _protocol[i] * (BIPS - splitBIPS) / BIPS);
                emit YieldDistributedSingle(distributedAsset, YDL_IZivoeGlobals(GBL).stZVE(), _protocol[i] * splitBIPS / BIPS);
                emit YieldDistributedSingle(distributedAsset, YDL_IZivoeGlobals(GBL).vestZVE(), _protocol[i] * (BIPS - splitBIPS) / BIPS);
            }
            else {
                IERC20(distributedAsset).safeTransfer(_recipient, _protocol[i]);
                emit YieldDistributedSingle(distributedAsset, _recipient, _protocol[i]);
            }
        }

        // Distribute senior and junior tranche earnings.
        IERC20(distributedAsset).safeApprove(YDL_IZivoeGlobals(GBL).stSTT(), _seniorTranche);
        IERC20(distributedAsset).safeApprove(YDL_IZivoeGlobals(GBL).stJTT(), _juniorTranche);
        YDL_IZivoeRewards(YDL_IZivoeGlobals(GBL).stSTT()).depositReward(distributedAsset, _seniorTranche);
        YDL_IZivoeRewards(YDL_IZivoeGlobals(GBL).stJTT()).depositReward(distributedAsset, _juniorTranche);
        emit YieldDistributedSingle(distributedAsset, YDL_IZivoeGlobals(GBL).stSTT(), _seniorTranche);
        emit YieldDistributedSingle(distributedAsset, YDL_IZivoeGlobals(GBL).stJTT(), _juniorTranche);

        // Distribute residual earnings.
        for (uint256 i = 0; i < residualRecipients.recipients.length; i++) {
            if (_residual[i] > 0) {
                address _recipient = residualRecipients.recipients[i];
                if (_recipient == YDL_IZivoeGlobals(GBL).stSTT() ||_recipient == YDL_IZivoeGlobals(GBL).stJTT()) {
                    IERC20(distributedAsset).safeApprove(_recipient, _residual[i]);
                    YDL_IZivoeRewards(_recipient).depositReward(distributedAsset, _residual[i]);
                    emit YieldDistributedSingle(distributedAsset, _recipient, _protocol[i]);
                }
                else if (_recipient == YDL_IZivoeGlobals(GBL).stZVE()) {
                    uint256 splitBIPS = (
                        IERC20(YDL_IZivoeGlobals(GBL).stZVE()).totalSupply() * BIPS
                    ) / (IERC20(YDL_IZivoeGlobals(GBL).stZVE()).totalSupply() + IERC20(YDL_IZivoeGlobals(GBL).vestZVE()).totalSupply());
                    IERC20(distributedAsset).safeApprove(YDL_IZivoeGlobals(GBL).stZVE(), _residual[i] * splitBIPS / BIPS);
                    IERC20(distributedAsset).safeApprove(YDL_IZivoeGlobals(GBL).vestZVE(), _residual[i] * (BIPS - splitBIPS) / BIPS);
                    YDL_IZivoeRewards(YDL_IZivoeGlobals(GBL).stZVE()).depositReward(distributedAsset, _residual[i] * splitBIPS / BIPS);
                    YDL_IZivoeRewards(YDL_IZivoeGlobals(GBL).vestZVE()).depositReward(distributedAsset, _residual[i] * (BIPS - splitBIPS) / BIPS);
                    emit YieldDistributedSingle(distributedAsset, YDL_IZivoeGlobals(GBL).stZVE(), _residual[i] * splitBIPS / BIPS);
                    emit YieldDistributedSingle(distributedAsset, YDL_IZivoeGlobals(GBL).vestZVE(), _residual[i] * (BIPS - splitBIPS) / BIPS);
                }
                else {
                    IERC20(distributedAsset).safeTransfer(_recipient, _residual[i]);
                    emit YieldDistributedSingle(distributedAsset, _recipient, _residual[i]);
                }
            }
        }

    }

    /// @notice Supplies yield directly to each tranche, divided up by nominal rate (same as normal with no retrospective
    ///         shortfall adjustment) for surprise rewards, manual interventions, and to simplify governance proposals by 
    ////        making use of accounting here. 
    /// @param amount Amount of distributedAsset() to supply.
    function supplementYield(uint256 amount) external {

        require(unlocked, "ZivoeYDL::supplementYield() !unlocked");

        (uint256 seniorSupp,) = YDL_IZivoeGlobals(GBL).adjustedSupplies();
    
        uint256 seniorRate = seniorRateNominal_RAY(amount, seniorSupp, targetAPYBIPS, daysBetweenDistributions);
        uint256 toSenior = (amount * seniorRate) / RAY;
        uint256 toJunior = amount.zSub(toSenior);

        emit YieldSupplemented(toSenior, toJunior);

        IERC20(distributedAsset).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(distributedAsset).safeApprove(YDL_IZivoeGlobals(GBL).stSTT(), toSenior);
        IERC20(distributedAsset).safeApprove(YDL_IZivoeGlobals(GBL).stJTT(), toJunior);
        YDL_IZivoeRewards(YDL_IZivoeGlobals(GBL).stSTT()).depositReward(distributedAsset, toSenior);
        YDL_IZivoeRewards(YDL_IZivoeGlobals(GBL).stJTT()).depositReward(distributedAsset, toJunior);

    }

    /// @notice View distribution information for protocol and residual earnings recipients.
    /// @return protocolEarningsRecipients The destinations for protocol earnings distributions.
    /// @return protocolEarningsProportion The proportions for protocol earnings distributions.
    /// @return residualEarningsRecipients The destinations for residual earnings distributions.
    /// @return residualEarningsProportion The proportions for residual earnings distributions.
    function viewDistributions() 
        external 
        view 
        returns(
            address[] memory protocolEarningsRecipients,
            uint256[] memory protocolEarningsProportion,
            address[] memory residualEarningsRecipients,
            uint256[] memory residualEarningsProportion
        ) 
    {
        return (
            protocolRecipients.recipients,
            protocolRecipients.proportion,
            residualRecipients.recipients,
            residualRecipients.proportion
        );
    }

    // ----------
    //    Math
    // ----------

    /**
        @notice     Calculates amount of annual yield required to meet target rate for both tranches.
        @param      sSTT = total supply of senior tranche token     (units = WEI)
        @param      sJTT = total supply of junior tranche token     (units = WEI)
        @param      Y    = target annual yield for senior tranche   (units = BIPS)
        @param      Q    = multiple of Y                            (units = BIPS)
        @param      T    = # of days between distributions          (units = integer)
        @dev        (Y * (sSTT + sJTT * Q / BIPS) * T / BIPS) / (365^2)
    */
    function yieldTarget(
        uint256 sSTT,
        uint256 sJTT,
        uint256 Y,
        uint256 Q,
        uint256 T
    ) public pure returns (uint256) {
        return (Y * (sSTT + sJTT * Q / BIPS) * T / BIPS) / (365^2);
    }

    /**
        @notice     Calculates % of yield attributable to senior tranche.
        @param      postFeeYield = yield distributable after fees   (units = WEI)
        @param      sSTT = total supply of senior tranche token     (units = WEI)
        @param      sJTT = total supply of junior tranche token     (units = WEI)
        @param      Y    = target annual yield for senior tranche   (units = BIPS)
        @param      Q    = multiple of Y                            (units = BIPS)
        @param      T    = # of days between distributions          (units = integer)
        @param      R    = # of distributions for retrospection     (units = integer)
        @return     rateSenior Yield attributable to senior tranche in BIPS.
    */
    function rateSenior_RAY(
        uint256 postFeeYield,
        uint256 sSTT,
        uint256 sJTT,
        uint256 Y,
        uint256 Q,
        uint256 T,
        uint256 R
    ) public view returns (uint256 rateSenior) {

        uint256 yT = yieldTarget(emaSTT, emaJTT, Y, Q, T);

        // CASE #1 => Shortfall.
        if (yT > postFeeYield) {
            return seniorRateShortfall_RAY(sSTT, sJTT, Q);
        }

        // CASE #2 => Excess, and historical under-performance.
        else if (yT >= emaYield && emaYield != 0) {
            return seniorRateCatchup_RAY(postFeeYield, yT, sSTT, sJTT, R, Q);
        }

        // CASE #3 => Excess, and out-performance.
        else {
            return seniorRateNominal_RAY(postFeeYield, sSTT, Y, T);
        }
    }

    /**
        @notice     Calculates % of yield attributable to senior tranche during excess but historical under-performance.
        @param      postFeeYield = yield distributable after fees  (units = WEI)
        @param      yT   = yieldTarget() return parameter          (units = WEI)
        @param      sSTT = total supply of senior tranche token    (units = WEI)
        @param      sJTT = total supply of junior tranche token    (units = WEI)
        @param      R    = # of distributions for retrospection    (units = integer)
        @param      Q    = multiple of Y                           (units = BIPS)
        @return     seniorRateCatchup Yield attributable to senior tranche in BIPS.
    */
    function seniorRateCatchup_RAY(
        uint256 postFeeYield,
        uint256 yT,
        uint256 sSTT,
        uint256 sJTT,
        uint256 R,
        uint256 Q
    ) public view returns (uint256 seniorRateCatchup) {
        return ((R + 1) * yT * RAY * WAD).zSub(R * emaYield * RAY * WAD).zDiv(
                postFeeYield * (WAD + (Q * sJTT * WAD / BIPS).zDiv(sSTT))
            ).min(RAY);
    }

    /**
        @notice     Calculates % of yield attributable to junior tranche.
        @param      sSTT = total supply of senior tranche token    (units = WEI)
        @param      sJTT = total supply of junior tranche token    (units = WEI)
        @param      Y    = % of yield attributable to seniors      (units = RAY)
        @param      Q    = senior to junior tranche target ratio   (units = BIPS)
        @return     rateJunior Yield attributable to junior tranche in BIPS.
    */
    function rateJunior_RAY(
        uint256 sSTT,
        uint256 sJTT,
        uint256 Y,
        uint256 Q
    ) public pure returns (uint256 rateJunior) {
        if (Y > RAY) {
           return 0;
        }
        else {
            return (Q * sJTT * Y / BIPS).zDiv(sSTT).min(RAY - Y); 
        }
        
    }

    /**
        @notice     Calculates proportion of yield attributed to senior tranche (no extenuating circumstances).
        @dev        Precision of this return value is in RAY (10**27 greater than actual value).
        @dev                 Y  * sSTT * T
                       ------------------------  *  RAY
                       (365 ^ 2) * postFeeYield
        @param      postFeeYield = yield distributable after fees  (units = WEI)
        @param      sSTT = total supply of senior tranche token    (units = WEI)
        @param      Y    = target annual yield for senior tranche  (units = BIPS)
        @param      T    = # of days between distributions         (units = integer)
        @return     seniorRateNominal Proportion of yield attributed to senior tranche (in RAY).
    */
    function seniorRateNominal_RAY(
        uint256 postFeeYield,
        uint256 sSTT,
        uint256 Y,
        uint256 T
    ) public pure returns (uint256 seniorRateNominal) {
        // TODO: Refer to below note.
        // NOTE: THIS WILL REVERT IF postFeeYield == 0 ?? ISSUE ??
        return ((RAY * Y * (sSTT) * T / BIPS) / (365^2)).zDiv(postFeeYield).min(RAY);
    }

    /**
        @notice     Calculates proportion of yield attributed to senior tranche (shortfall occurence).
        @dev        Precision of this return value is in RAY (10**27 greater than actual value).
        @dev                   WAD
                       -------------------------  *  RAY
                                 Q * sJTT * WAD      
                        WAD  +   --------------
                                      sSTT
        @param      sSTT = total supply of senior tranche token    (units = WEI)
        @param      sJTT = total supply of junior tranche token    (units = WEI)
        @param      Q    = senior to junior tranche target ratio   (units = integer)
        @return     seniorRateShortfall Proportion of yield attributed to senior tranche (in RAY).
    */
    function seniorRateShortfall_RAY(
        uint256 sSTT,
        uint256 sJTT,
        uint256 Q
    ) public pure returns (uint256 seniorRateShortfall) {
        return (WAD * RAY).zDiv(WAD + (Q * sJTT * WAD / BIPS).zDiv(sSTT)).min(RAY);
    }

    /**
        @notice Returns a given value's EMA based on prior and new values.
        @dev    Exponentially weighted moving average, written in float arithmatic as:
                                     newval - avg_n
                avg_{n+1} = avg_n + ----------------    
                                        min(N,t)
        @param  avg = The current value (likely an average).
        @param  newval = The next value to add to "avg".
        @param  N = Number of steps we are averaging over (nominally, it is infinite).
        @param  t = Number of time steps total that have occurred, only used when t < N.
        @return nextavg New EMA based on prior and new values.
    */
    function ema(
        uint256 avg,
        uint256 newval,
        uint256 N,
        uint256 t
    ) public pure returns (uint256 nextavg) {
        if (N < t) {
            t = N; // Use the count if we are still in the first window.
        }
        uint256 _diff = (WAD * (newval.zSub(avg))).zDiv(t); // newval > avg.
        if (_diff == 0) { // newval - avg < t.
            _diff = (WAD * (avg.zSub(newval))).zDiv(t);   // abg > newval.
            nextavg = ((avg * WAD).zSub(_diff)).zDiv(WAD); // newval < avg.
        } else {
            nextavg = (avg * WAD + _diff).zDiv(WAD); // newval > avg.
        }
    }

}