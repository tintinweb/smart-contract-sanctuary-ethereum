//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Voting.sol";

/// @title staking contract for stake uniswap v2 lp tokens
/// @dev reward calculates every rewardPeriod and depends on rewardPercent and lpAmount per period
contract Staking is AccessControl {
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    struct Stake {
        uint256 lpAmount;
        uint256 rewardAmount;
        uint32 startTime;
    }

    IERC20 private tokenPair;
    IERC20 private rewardToken;

    address private _votingAddress;

    mapping(address => Stake) private _stakes;

    uint32 private _freezePeriod;
    uint32 private _rewardPeriod = 7 days;
    uint32 private _rewardPercent = 3;

    bytes32 private _whitelistHash;

    event Staked(address from, uint256 amount);
    event Unstaked(address to, uint256 amount);
    event Claimed(address to, uint256 amount);

    error TokensFreezed();
    error ActiveVotingExists();
    error ZeroRewards();
    error AccessForbiden();

    /// @notice sets state and roles
    /// @param tokenPair_ address of staking lp token
    /// @param rewardToken_ address of reward token
    /// @param votingAddress address of dao voting contract
    constructor(
        IERC20 tokenPair_,
        IERC20 rewardToken_,
        address votingAddress,
        bytes32 whitelistHash_
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DAO_ROLE, votingAddress);
        _setRoleAdmin(DAO_ROLE, DEFAULT_ADMIN_ROLE);
        tokenPair = tokenPair_;
        rewardToken = rewardToken_;
        _votingAddress = votingAddress;
        _whitelistHash = whitelistHash_;
    }

    /// @notice stake lp tokens
    /// @param amount of lp tokens
    function stake(uint256 amount, bytes32[] calldata proof) public {
        if (
            !MerkleProof.verify(proof, _whitelistHash, keccak256(abi.encodePacked(msg.sender)))
        ) {
            revert AccessForbiden();
        }

        tokenPair.transferFrom(msg.sender, address(this), amount);

        _stakes[msg.sender].rewardAmount += _calcReward(msg.sender);
        _stakes[msg.sender].lpAmount += amount;
        _stakes[msg.sender].startTime = uint32(block.timestamp);

        emit Staked(msg.sender, amount);
    }

    /// @notice unstake all lp tokens
    function unstake() public {
        if (block.timestamp < _stakes[msg.sender].startTime + _freezePeriod) {
            revert TokensFreezed();
        }

        uint32 lastFinishDate = Voting(_votingAddress).lastFinishDate(
            msg.sender
        );
        if (block.timestamp < lastFinishDate) {
            revert ActiveVotingExists();
        }

        _stakes[msg.sender].rewardAmount += _calcReward(msg.sender);
        uint256 lpAmount = _stakes[msg.sender].lpAmount;
        _stakes[msg.sender].lpAmount = 0;
        tokenPair.transfer(msg.sender, lpAmount);

        emit Unstaked(msg.sender, lpAmount);
    }

    /// @notice claim reward tokens
    function claim() public {
        uint256 rewardAmount = _stakes[msg.sender].rewardAmount +
            _calcReward(msg.sender);
        if (rewardAmount == 0) revert ZeroRewards();

        _stakes[msg.sender].rewardAmount = 0;
        _stakes[msg.sender].startTime = uint32(block.timestamp);
        rewardToken.transfer(msg.sender, rewardAmount);

        emit Claimed(msg.sender, rewardAmount);
    }

    /// @notice sets freeze period
    /// @param freezePeriod_ freeze period in seconds
    function setFreezePeriod(uint32 freezePeriod_) external onlyRole(DAO_ROLE) {
        _freezePeriod = freezePeriod_;
    }

    /// @notice sets reward period
    /// @param rewardPeriod_ reward period in seconds
    function setRewardPeriod(uint32 rewardPeriod_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rewardPeriod = rewardPeriod_;
    }

    /// @notice sets reward percent
    /// @param rewardPercent_ reward percent
    function setRewardPercent(uint32 rewardPercent_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rewardPercent = rewardPercent_;
    }

    /// @notice sets whitelist hash
    /// @param whitelistHash_ whitelist merkle tree root hash
    function setWhitelistHash(bytes32 whitelistHash_) external onlyRole(DAO_ROLE) {
        _whitelistHash = whitelistHash_;
    }

    /// @notice returns stake info
    /// @param addr address of user
    /// @return Stake stake info
    function getStakeData(address addr) external view returns (Stake memory) {
        return _stakes[addr];
    }

    /// @notice returns freeze period
    /// @return _freezePeriod freeze period in seconds
    function freezePeriod() external view returns (uint32) {
        return _freezePeriod;
    }

    /// @notice returns reward period
    /// @return _rewardPeriod reward period  in seconds
    function rewardPeriod() external view returns (uint32) {
        return _rewardPeriod;
    }

    /// @notice returns reward percent
    /// @return _rewardPercent reward percent
    function rewardPercent() external view returns (uint32) {
        return _rewardPercent;
    }

    /// @notice returns whitelist hash
    /// @return _whitelistHash whitelist merkle tree root hash
    function whitelistHash() external view returns (bytes32) {
        return _whitelistHash;
    }

    /// @notice calculates amount of reward tokens for period
    /// @param addr address of user
    /// @return reward tokens amount
    function _calcReward(address addr) private view returns (uint256) {
        uint256 rewardPeriodsCount = (block.timestamp -
            _stakes[addr].startTime) / _rewardPeriod;
        return
            (rewardPeriodsCount * _stakes[addr].lpAmount * _rewardPercent) / 100;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Staking.sol";

/// @title DAO Voting contract
/// @author fukktalent
/// @notice voting for purposes. one token is one vote
contract Voting is AccessControl {
    struct Proposal {
        bytes callData;
        address recipient;
        string description;
        uint32 finishDate;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    bytes32 public constant CHAIRMAN_ROLE = keccak256("CHAIRMAN_ROLE");

    uint32 private _debatingPeriodDuration;
    uint256 private _minimumQuorum;

    address private _stakingAddress;

    mapping(address => uint32) private _lastFinishDates;

    mapping(uint64 => Proposal) private _proposals;
    uint64 private _proposalCount;

    // user => (proposal id => is voted)
    mapping(address => mapping(uint64 => bool)) private _isVoted;

    /// @notice when proposal successfuly accepted
    /// @param proposalId id of proposal
    /// @param votesFor votes for proposal
    /// @param votesAgainst votes against proposal
    /// @param funcResult result of proposal func
    event ProposalAccepted(
        uint64 proposalId,
        uint256 votesFor,
        uint256 votesAgainst,
        bytes funcResult
    );

    /// @notice when votes < _minimumQuorum or votes against > votes for
    /// @param proposalId id of proposal
    /// @param votesFor votes for proposal
    /// @param votesAgainst votes against proposal
    event ProposalDeclined(
        uint64 proposalId,
        uint256 votesFor,
        uint256 votesAgainst
    );

    /// @notice when call proposal signature failed
    /// @param proposalId id of proposal
    event ProposalFailed(uint64 proposalId);

    /// @notice when proposal was create
    /// @param proposalId id of proposal
    /// @param callData encoded proposal function signature 
    /// @param recipient contract address on which will call proposal function
    /// @param description of proposal
    event ProposalVotingStarted(
        uint64 proposalId,
        bytes callData,
        address recipient,
        string description
    );

    error InvalidProposal();
    error NotActiveProposalTime();
    error StillActiveProposalTime();
    error ActiveBalance();
    error InvalidAmount();
    error AlreadyVoted();
    error ZeroStaked();

    modifier onlyActive(uint64 proposalId) {
        if (_proposals[proposalId].finishDate == 0) revert InvalidProposal();
        _;
    }

    /// @notice set init data and grand DEFAULT_ADMIN_ROLE to owner
    /// @param debatingPeriodDuration_ voting duration in seconds
    /// @param minimumQuorum_ minimum number of votes at which voting will take place
    /// @param chairman address to set chairman
    constructor(
        uint32 debatingPeriodDuration_,
        uint256 minimumQuorum_,
        address chairman
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CHAIRMAN_ROLE, chairman);
        _debatingPeriodDuration = debatingPeriodDuration_;
        _minimumQuorum = minimumQuorum_;
    }

    /// @notice creates porposal and init voting
    /// @param callData encoded proposal function signature 
    /// @param recipient contract address on which will call proposal function
    /// @param description of proposal
    function addProposal(
        bytes memory callData,
        address recipient,
        string memory description
    ) external onlyRole(CHAIRMAN_ROLE) {
        uint64 proposalId = _proposalCount;
        _proposalCount++;

        Proposal storage proposal_ = _proposals[proposalId];
        proposal_.callData = callData;
        proposal_.recipient = recipient;
        proposal_.description = description;
        proposal_.finishDate = uint32(block.timestamp) + _debatingPeriodDuration;

        emit ProposalVotingStarted(
            proposalId,
            callData,
            recipient,
            description
        );
    }

    /// @notice votes for proposal, use full token balance 
    /// @param proposalId id of proposal
    /// @param isFor true - for proposal, false - against proposal
    function vote(
        uint64 proposalId, 
        bool isFor
    )
        external
        onlyActive(proposalId)
    {
        if (_isVoted[msg.sender][proposalId]) revert AlreadyVoted();

        if (_proposals[proposalId].finishDate <= block.timestamp) {
            revert NotActiveProposalTime();
        }

        uint256 balance = Staking(_stakingAddress).getStakeData(msg.sender).lpAmount;
        if (balance == 0) revert ZeroStaked();

        _isVoted[msg.sender][proposalId] = true;

        if (
            _lastFinishDates[msg.sender] < _proposals[proposalId].finishDate
        ) {
            _lastFinishDates[msg.sender] = _proposals[proposalId].finishDate;
        }

        if (isFor) {
            _proposals[proposalId].votesFor += balance;
        } else {
            _proposals[proposalId].votesAgainst += balance;
        }
    }

    /// @notice finish voting, three cases: 
    ///         proposal accepted and function call completed successfully,
    ///         proposal accepted and function call failed,
    ///         proposal rejected
    /// @dev deletes proposal from mapping for gas optimisation, emit event to save info
    /// @param proposalId a parameter just like in doxygen (must be followed by parameter name)
    function finishProposal(uint64 proposalId) external onlyActive(proposalId) {
        Proposal storage proposal_ = _proposals[proposalId];
        if (proposal_.finishDate > block.timestamp)
            revert StillActiveProposalTime();

        if (
            proposal_.votesFor + proposal_.votesAgainst >= _minimumQuorum &&
            proposal_.votesFor > proposal_.votesAgainst
        ) {
            (bool success, bytes memory res) = proposal_.recipient.call(
                proposal_.callData
            );

            if (success) {
                emit ProposalAccepted(
                    proposalId,
                    proposal_.votesFor,
                    proposal_.votesAgainst,
                    res
                );
            } else {
                emit ProposalFailed(proposalId);
            }
        } else {
            emit ProposalDeclined(
                proposalId,
                proposal_.votesFor,
                proposal_.votesAgainst
            );
        }

        delete _proposals[proposalId];
    }

    /// @notice sets staking address
    /// @param staking address of staking
    function setStakingAddress(
        address staking
    )
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _stakingAddress = staking;
    }

    /// @notice debatingPeriodDuration getter
    /// @return _debatingPeriodDuration voting duration in seconds
    function debatingPeriodDuration() external view returns (uint32) {
        return _debatingPeriodDuration;
    }

    /// @notice minimumQuorum getter
    /// @return _minimumQuorum minimum number of votes at which voting will take place
    function minimumQuorum() external view returns (uint256) {
        return _minimumQuorum;
    }

    /// @notice user data getter
    /// @param addr addres of user
    /// @return user user data: balance and defrost time
    function lastFinishDate(address addr) external view returns (uint32) {
        return _lastFinishDates[addr];
    }

    /// @notice proposal getter
    /// @param proposalId id of proposal
    /// @return proposal proposal data
    function proposal(uint64 proposalId)
        external
        view
        returns (Proposal memory)
    {
        return _proposals[proposalId];
    }

    /// @notice proposalsCount getter
    /// @return _proposalCount amount of proposals for all time
    function proposalsCount() external view returns (uint64) {
        return _proposalCount;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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