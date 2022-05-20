//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/// @title Votings smart-contract based on DAO
/// @author AkylbekAD
/// @notice You can participate in Votings depositing ExampleToken (EXT) 
/// @dev Could be redeployed with own ERC20 token and other parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @dev Throw this error if account without rights try to use chairman functions
error SenderDontHasRights(address sender);

/// @dev Throw this error if voting doesn`t get minimal quorum of votes
error MinimalVotingQuorum(uint256 votingIndex, uint256 votingQuorum);

contract DAOVotings is AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter public Counter;

    /// @notice Person allowed to create Votings
    address public chairman;

    /// @notice ERC20 contract address tokens avaliable to deposit
    address public erc20address;

    /// @notice Minimum amount of votes for Voting to be accomplished
    uint256 public minimumQuorum;

    /// @notice Minimum period of time for each Voting
    uint256 public minimumDuration = 3 days;

    /// @dev Bytes format for ADMIN role
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev Bytes format for CHAIRMAN role
    bytes32 public constant CHAIRMAN = keccak256("CHAIRMAN");

    /// @dev Structure of each proposal Voting
    struct Voting {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 debatingPeriodDuration;
        address contractAddress;
        bytes callData;
        bool votingFinished;
        mapping (address => uint256) votes;
    }

    /// @dev Structure of each voter info
    struct Voter {
        uint256 votingPower;
        uint256 depositDuration;
    }

    /// @notice View voter`s voting power and deposit freeze time
    /// @dev Voter`s info could change only be themselfs 
    mapping (address => Voter) public voterInfo;

    /// @notice View Voting`s info by it`s index
    /// @dev Mapping stores all Votings info
    mapping (uint256 => Voting) public getProposal;

    event ProposalStarted(string description, uint256 votingIndex, uint256 debatingPeriodDuration, address contractAddress, bytes callData);
    event VoteGiven(address voter, uint256 votingIndex, bool decision, uint256 votingPower);
    event ProposalFinished(uint256 votingIndex, bool proposalCalled);

    /// @dev First chairman is deployer, must input token address and minimum quorum for votings
    constructor(address erc20, uint256 quorum) {
        chairman = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
        _setRoleAdmin(CHAIRMAN, ADMIN);
        erc20address = erc20;
        minimumQuorum = quorum;
    }

    /// @dev Modifier checks sender to be Chairman or Admin, otherwise reverts with error
    modifier isChairman() {
        if(!hasRole(ADMIN, msg.sender) && !hasRole(CHAIRMAN, msg.sender)) {
            revert SenderDontHasRights(msg.sender);
        }
        _;
    }

    /// @dev Chaiman or Admin can set a minimum Voting Quorum
    function setMinimumQuorum(uint256 amount) external isChairman {
        minimumQuorum = amount;
    }

    /// @dev Chaiman or Admin can change an ERC20 token address
    function setERC20address(address contractAddress) external isChairman {
        erc20address = contractAddress;
    }

    /// @notice Deposit tokens to have voting power in Votings
    /// @dev Users have to approve tokens to contract first
    /// @param amount is amount of approved tokens by user to contract
    function deposit(uint256 amount) external {
        IERC20(erc20address).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        voterInfo[msg.sender].votingPower += amount;
        voterInfo[msg.sender].depositDuration = block.timestamp;
    }

    /// @notice Only chairman or admin can start new Votings with proposal
    /// @dev Creates new voting and emits ProposalStarted event
    /// @param duration value cant be less then minimumDuration value
    /// @param contractAddress is address of contract callData on which should be called
    /// @param callData is hash which be decoded to abi and parametres to be called at contract
    function addProposal(string memory description, uint256 duration, address contractAddress, bytes memory callData) public isChairman {
        Counter.increment();
        uint256 index = Counter.current();

        getProposal[index].description = description;
        getProposal[index].callData = callData;
        getProposal[index].contractAddress = contractAddress;

        if (duration < minimumDuration) {
            getProposal[index].debatingPeriodDuration = block.timestamp + minimumDuration;
        } else {
            getProposal[index].debatingPeriodDuration = block.timestamp + duration;
        }

        emit ProposalStarted(description, index, getProposal[index].debatingPeriodDuration, contractAddress, callData);
    }

    /// @notice Make your decision 'true' to vote for or 'false' to vote against with deposoted tokens
    /// @dev Voters can vote only once at each voting
    /// @param votesAmount is amount of deposited tokens or 'votingPower'
    /// @param decision must be 'true' or 'false'
    function vote(uint256 votingIndex, uint256 votesAmount, bool decision) external {
        require(block.timestamp < getProposal[votingIndex].debatingPeriodDuration, "Voting have been ended");
        require(votesAmount <= voterInfo[msg.sender].votingPower, "Not enough deposited tokens");
        require(getProposal[votingIndex].votes[msg.sender] == 0, "You have already voted");

        if (decision) {
            getProposal[votingIndex].votesFor += votesAmount;
        } else {
            getProposal[votingIndex].votesAgainst += votesAmount;
        }

        if (voterInfo[msg.sender].depositDuration < getProposal[votingIndex].debatingPeriodDuration) {
            voterInfo[msg.sender].depositDuration = getProposal[votingIndex].debatingPeriodDuration;
        }

        getProposal[votingIndex].votes[msg.sender] += votesAmount;

        emit VoteGiven(msg.sender, votingIndex, decision, votesAmount);
    }

    /// @notice Finish voting and do proposal call
    /// @dev Calls proposalCall function with voting parameters and emits ProposalCalled event
    function finishProposal(uint256 votingIndex) external {
        require(block.timestamp >= getProposal[votingIndex].debatingPeriodDuration, "Debating period didnt pass");
        require(!getProposal[votingIndex].votingFinished, "Proposal voting was already finished or not accepted");

        uint256 votingQuorum = getProposal[votingIndex].votesFor + getProposal[votingIndex].votesAgainst;

        if (votingQuorum < minimumQuorum) {
            getProposal[votingIndex].votingFinished = true;

            emit ProposalFinished(votingIndex, false);

            revert MinimalVotingQuorum(votingIndex, votingQuorum);
        }

        if (getProposal[votingIndex].votesFor > getProposal[votingIndex].votesAgainst) {
            proposalCall(getProposal[votingIndex].contractAddress, getProposal[votingIndex].callData);

            emit ProposalFinished(votingIndex, true);
        }

        getProposal[votingIndex].votingFinished = true;
    }

    /// @notice Returns deposited tokens to sender if duration time passed
    function returnDeposit() external {
        require(voterInfo[msg.sender].depositDuration < block.timestamp, "Deposit duration does not pass");

        uint256 depositTokens = voterInfo[msg.sender].votingPower;
        voterInfo[msg.sender].votingPower = 0;
        IERC20(erc20address).transfer(msg.sender, depositTokens);
    }

    function startChairmanElection(address newChairman, uint256 duration) external {
        require(hasRole(ADMIN, msg.sender), "You are not an Admin");

        bytes memory callData = abi.encodeWithSignature("changeChairman(address)", newChairman);
        addProposal("Proposal for a new Chairman", duration, address(this), callData);
    }

    /// @notice Get last voting index or number of all created proposals
    function getLastIndex() external view returns(uint256) {
        return Counter.current();
    }

    /// @notice Get amount of votes made by account at Voting
    function getVotes(uint256 votingIndex, address voter) external view returns(uint256) {
        return getProposal[votingIndex].votes[voter];
    }

    /// @dev Function that called if proposal voting is astablished succesfull
    function proposalCall(address contractAddress, bytes memory callData) private {
        (bool success, ) = contractAddress.call{value: 0} (
            callData
        );
        require(success, "Error proposalcall");
    }

    /// @dev Can only be called throw addProposal function by voting
    function changeChairman(address newChairman) external {
        require(msg.sender == address(this), "Must called throw proposal");
        chairman = newChairman;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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