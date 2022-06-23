//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./matic/BasicMetaTransaction.sol";
import "./interfaces/IMogulSmartWallet.sol";
import "./interfaces/IVotingMasterChef.sol";
import "./utils/Sqrt.sol";

contract Voting is BasicMetaTransaction, AccessControl {
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    // The Stars token.
    IERC20 public stars;
    // The NFT.
    IERC1155 public mgl;
    // The staking contrract.
    IVotingMasterChef votingMasterChef;
    // Max amount per round
    uint256 public constant MAX = 5;

    enum VotingRoundState {
        Active,
        Paused,
        Canceled,
        Executed
    }

    struct VotingRound {
        // list available to vote on.
        // The list must be filled left to right, leaving empty slots as 0.
        uint256[MAX] ids;
        // voting starts on this block.
        uint256 startVoteBlockNum;
        // voting ends at this block.
        uint256 endVoteBlockNum;
        // total Stars rewards for the round.
        uint256 starsRewards;
        VotingRoundState votingRoundState;
        // mapping variables: id
        mapping(uint256 => uint256) votes;
        // mapping variables: userAddress
        mapping(address => bool) rewardsClaimed;
        // mapping variables: userAddress, id
        mapping(address => mapping(uint256 => uint256)) totalStarsEntered;
    }

    VotingRound[] public votingRounds;

    event VotingRoundCreated(
        uint256[MAX] ids,
        uint256 startVoteBlockNum,
        uint256 endVoteBlockNum,
        uint256 starsRewards,
        uint256 votingRound
    );
    event VotingRoundPaused(uint256 roundId);
    event VotingRoundUnpaused(uint256 roundId);
    event VotingRoundCanceled(uint256 roundId);
    event VotingRoundExecuted(uint256 roundId);

    event Voted(
        address voter,
        uint256 roundId,
        uint256 id,
        uint256 starsAmountMantissa,
        uint256 quadraticVoteScore
    );
    event Unvoted(
        address voter,
        uint256 roundId,
        uint256 id,
        uint256 starsAmountMantissa,
        uint256 quadraticVoteScore
    );

    modifier onlyAdmin() {
        require(hasRole(ROLE_ADMIN, msgSender()), "Sender is not admin");
        _;
    }

    modifier votingRoundMustExist(uint256 roundId) {
        require(
            roundId < votingRounds.length,
            "Voting Round id does not exist yet"
        );
        _;
    }

    /**
     * @dev Sets the admin role and records the stars, item
     * and staking contract addresses. Also approves Stars
     * for the staking contract.
     *
     * Parameters:
     *
     * - _admin: admin of the smart wallet.
     * - _stars: Stars token address.
     * - _mgl: item address.
     * - _votingMasterChef: staking contract address.
     *
     */
    constructor(
        address _admin,
        address _stars,
        address _mgl,
        address _votingMasterChef
    ) {
        _setupRole(ROLE_ADMIN, _admin);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);

        stars = IERC20(_stars);
        mgl = IERC1155(_mgl);
        votingMasterChef = IVotingMasterChef(_votingMasterChef);
        // Note: type(uint256).max is max number
        stars.approve(_votingMasterChef, type(uint256).max);
    }

    /**
     * @dev Returns all item ids of the voting round.
     * id 0 represents empty slot.
     *
     * Parameters:
     *
     * - votingRoundId: id of the voting round.
     */
    function getIds(uint256 votingRoundId)
        external
        view
        returns (uint256[MAX] memory)
    {
        return votingRounds[votingRoundId].ids;
    }

    /**
     * @dev Returns all item votes of the voting round.
     *
     * Parameters:
     *
     * - votingRoundId: voting round id.
     */
    function getVotes(uint256 votingRoundId)
        external
        view
        returns (uint256[MAX] memory)
    {
        VotingRound storage votingRound = votingRounds[votingRoundId];
        uint256[MAX] memory votes;
        for (uint256 i; i < MAX; i++) {
            votes[i] = (votingRound.votes[votingRound.ids[i]]);
        }
        return votes;
    }

    /**
     * @dev Returns the details of the voting round.
     *
     * Parameters:
     *
     * - votingRoundId: voting round id.
     */
    function getVotingRound(uint256 votingRoundId)
        external
        view
        returns (
            uint256[MAX] memory,
            uint256[MAX] memory,
            uint256,
            uint256,
            uint256,
            VotingRoundState
        )
    {
        VotingRound storage votingRound = votingRounds[votingRoundId];
        uint256[MAX] memory ids = votingRound.ids;
        uint256[MAX] memory votes;

        for (uint256 i; i < MAX; i++) {
            votes[i] = (votingRound.votes[votingRound.ids[i]]);
        }
        return (
            ids,
            votes,
            votingRound.startVoteBlockNum,
            votingRound.endVoteBlockNum,
            votingRound.starsRewards,
            votingRound.votingRoundState
        );
    }

    /**
     * @dev Returns the total stars entered by a user.
     *
     * Parameters:
     *
     * - userAddress: user's address.
     * - id: item round id.
     * - votingRoundId: voting round id.
     */
    function getUserTotalStarsEntered(
        address userAddress,
        uint256 id,
        uint256 votingRoundId
    ) external view returns (uint256) {
        uint256 userTotalStarsEntered = votingRounds[votingRoundId]
            .totalStarsEntered[userAddress][id];
        return userTotalStarsEntered;
    }

    /**
     * @dev Returns if user has already claimed their Stars rewards.
     *
     * Parameters:
     *
     * - userAddress: user's address.
     * - votingRoundId: voting round id.
     */
    function didUserClaimRewards(address userAddress, uint256 votingRoundId)
        external
        view
        returns (bool)
    {
        bool _didUserClaimRewards = votingRounds[votingRoundId].rewardsClaimed[
            userAddress
        ];
        return _didUserClaimRewards;
    }

    /**
     * @dev Creates a new voting round.
     *
     * Parameters:
     *
     * - ids: list of ids, filled from left to right.
     * Id 0 represents empty slot.
     * - startVoteBlockNum: the block voting will start on.
     * - endVoteBlockNum: the block voting will end on.
     * - starsRewards: the total Stars rewards to distribute to voters.
     *
     * Requirements:
     *
     * - Start Vote Block must be less than End Vote Block.
     * - Caller must be an admin.
     */
    function createNewVotingRound(
        uint256[MAX] calldata ids,
        uint256 startVoteBlockNum,
        uint256 endVoteBlockNum,
        uint256 starsRewards
    ) external onlyAdmin {
        require(
            startVoteBlockNum < endVoteBlockNum,
            "Start block must be less than end block"
        );
        uint256 idx = votingRounds.length;
        votingRounds.push();
        VotingRound storage votingRound = votingRounds[idx];

        votingRound.ids = ids;
        votingRound.startVoteBlockNum = startVoteBlockNum;
        votingRound.endVoteBlockNum = endVoteBlockNum;
        votingRound.starsRewards = starsRewards;
        votingRound.votingRoundState = VotingRoundState.Active;

        stars.transferFrom(msgSender(), address(this), starsRewards);

        // transfer stars for rewards
        votingMasterChef.add(
            startVoteBlockNum,
            endVoteBlockNum,
            starsRewards,
            false
        );

        emit VotingRoundCreated(
            ids,
            startVoteBlockNum,
            endVoteBlockNum,
            starsRewards,
            votingRounds.length
        );
    }

    /**
     * @dev Pause a voting round.
     *
     * Parameters:
     *
     * - roundId: Voting round id.
     *
     * Requirements:
     *
     * - Caller must be an admin.
     * - Voting round must exist.
     * - Voting round must be active.
     * - Voting round has not ended.
     */
    function pauseVotingRound(uint256 roundId)
        external
        onlyAdmin
        votingRoundMustExist(roundId)
    {
        VotingRound storage votingRound = votingRounds[roundId];

        require(
            votingRound.votingRoundState == VotingRoundState.Active,
            "Only active voting rounds can be paused"
        );
        require(
            votingRound.endVoteBlockNum >= block.number,
            "Voting Round has already concluded"
        );
        votingRound.votingRoundState = VotingRoundState.Paused;

        emit VotingRoundPaused(roundId);
    }

    /**
     * @dev Unpause a voting round.
     *
     * Parameters:
     *
     * - roundId: Voting round id.
     *
     * Requirements:
     *
     * - Caller must be an admin.
     * - Voting round must exist.
     * - Voting round must be paused.
     */
    function unpauseVotingRound(uint256 roundId)
        external
        onlyAdmin
        votingRoundMustExist(roundId)
    {
        VotingRound storage votingRound = votingRounds[roundId];

        require(
            votingRound.votingRoundState == VotingRoundState.Paused,
            "Only paused voting rounds can be unpaused"
        );
        votingRound.votingRoundState = VotingRoundState.Active;

        emit VotingRoundUnpaused(roundId);
    }

    /**
     * @dev Cancel a voting round.
     *
     * Parameters:
     *
     * - roundId: Voting round id.
     *
     * Requirements:
     *
     * - Caller must be an admin.
     * - Voting round must exist.
     * - Voting round must be active or paused.
     */
    function cancelVotingRound(uint256 roundId)
        external
        onlyAdmin
        votingRoundMustExist(roundId)
    {
        VotingRound storage votingRound = votingRounds[roundId];

        require(
            votingRound.votingRoundState == VotingRoundState.Active ||
                votingRound.votingRoundState == VotingRoundState.Paused,
            "Only active or paused voting rounds can be cancelled"
        );
        require(
            block.number <= votingRound.endVoteBlockNum,
            "Voting Round has already concluded"
        );
        votingRound.votingRoundState = VotingRoundState.Canceled;

        emit VotingRoundCanceled(roundId);
    }

    /**
     * @dev Execute a voting round.
     *
     * Parameters:
     *
     * - roundId: Voting round id.
     *
     * Requirements:
     *
     * - Caller must be an admin.
     * - Voting round must exist.
     * - Voting round must be active.
     * - Voting round has not ended.
     */
    function executeVotingRound(uint256 roundId)
        external
        onlyAdmin
        votingRoundMustExist(roundId)
    {
        VotingRound storage votingRound = votingRounds[roundId];

        require(
            votingRound.votingRoundState == VotingRoundState.Active,
            "Only active voting rounds can be executed"
        );
        require(
            votingRound.endVoteBlockNum < block.number,
            "Voting round has not ended"
        );
        votingRound.votingRoundState = VotingRoundState.Executed;

        emit VotingRoundExecuted(roundId);
    }

    /**
     * @dev Returns the total amount of voting rounds
     * that have been created.
     *
     */
    function totalVotingRounds() external view returns (uint256) {
        return votingRounds.length;
    }

    /**
     * @dev Checks if the caller is the owner of the Mogul Smart Wallet and return its address.
     * Return the caller's addres if it is declared smart wallet is not used.
     *
     * Parameters:
     *
     * - isMogulSmartWallet: Whether or not smart wallet is used.
     * - mogulSmartWallet: address of the smart wallet, Zero address is passed if not used.
     * - msgSender: address of the caller.
     *
     */
    function _verifySmartWalletOwner(
        bool isMogulSmartWallet,
        address mogulSmartWallet,
        address msgSender
    ) internal returns (address) {
        if (isMogulSmartWallet) {
            require(
                msgSender == IMogulSmartWallet(mogulSmartWallet).owner(),
                "Invalid Mogul Smart Wallet Owner"
            );
            return mogulSmartWallet;
        } else {
            return msgSender;
        }
    }

    /**
     * @dev Vote by staking Stars.
     *
     * Parameters:
     *
     * - roundId: voting round id.
     * - id: id to vote for.
     * - starsAmountMantissa: total Stars to stake.
     * - isMogulSmartWallet: Whether or not smart wallet is used.
     * - mogulSmartWallet: address of the smart wallet, Zero address is passed if not used.
     *
     * Requirements:
     *
     * - Voting round id must exists.
     * - Must deposit at least 1 Stars token.
     * - id must be in voting round.
     * - Voting round must be active.
     * - Voting round must be started and has not ended.
     */
    function voteFor(
        uint256 roundId,
        uint256 id,
        uint256 starsAmountMantissa,
        bool isMogulSmartWallet,
        address mogulSmartWalletAddress
    ) external votingRoundMustExist(roundId) {
        require(
            starsAmountMantissa >= 1 ether,
            "Must deposit at least 1 Stars token"
        );

        address _msgSender = _verifySmartWalletOwner(
            isMogulSmartWallet,
            mogulSmartWalletAddress,
            msgSender()
        );

        VotingRound storage votingRound = votingRounds[roundId];

        uint256[MAX] memory ids = votingRound.ids;
        require(
            id != 0 &&
                (id == ids[0] ||
                    id == ids[1] ||
                    id == ids[2] ||
                    id == ids[3] ||
                    id == ids[4]),
            "Item Id is not in voting round"
        );

        require(
            votingRound.votingRoundState == VotingRoundState.Active,
            "Can only vote in active rounds"
        );

        require(
            votingRound.startVoteBlockNum <= block.number &&
                block.number <= votingRound.endVoteBlockNum,
            "Voting round has not started or has ended"
        );

        uint256 quadraticVoteScoreOld = Sqrt.sqrt(
            votingRound.totalStarsEntered[_msgSender][id] / 1 ether
        );

        votingRound.totalStarsEntered[_msgSender][id] =
            votingRound.totalStarsEntered[_msgSender][id] +
            starsAmountMantissa;

        uint256 quadraticVoteScoreNew = Sqrt.sqrt(
            votingRound.totalStarsEntered[_msgSender][id] / 1 ether
        );

        votingRound.votes[id] =
            votingRound.votes[id] +
            quadraticVoteScoreNew -
            quadraticVoteScoreOld;

        votingMasterChef.deposit(roundId, starsAmountMantissa, _msgSender);

        emit Voted(
            _msgSender,
            roundId,
            id,
            starsAmountMantissa,
            quadraticVoteScoreNew
        );
    }

    /**
     * @dev Remove vote for an item by withdrawing Stars, and forgoing Stars rewards.
     *
     * Parameters:
     *
     * - roundId: voting round id.
     * - id: item id to vote for.
     * - starsAmountMantissa: total Stars to stake.
     * - isMogulSmartWallet: Whether or not smart wallet is used.
     * - mogulSmartWallet: address of the smart wallet, Zero address is passed if not used.
     *
     * Requirements:
     *
     * - Voting round id must exists.
     * - Must withdraw more than 0 Stars token.
     * - Must have enough Stars deposited to withdraw.
     * - Item Id must be in voting round.
     * - Voting round must be active.
     * - Voting round must be started and has not ended.
     */
    function removeVoteFor(
        uint256 roundId,
        uint256 id,
        uint256 starsAmountMantissa,
        bool isMogulSmartWallet,
        address mogulSmartWalletAddress
    ) external votingRoundMustExist(roundId) {
        require(starsAmountMantissa > 0, "Cannot remove 0 votes");

        address _msgSender = _verifySmartWalletOwner(
            isMogulSmartWallet,
            mogulSmartWalletAddress,
            msgSender()
        );

        VotingRound storage votingRound = votingRounds[roundId];

        uint256[MAX] memory ids = votingRound.ids;
        require(
            id == ids[0] ||
                id == ids[1] ||
                id == ids[2] ||
                id == ids[3] ||
                id == ids[4],
            "Item Id is not in voting round"
        );
        require(
            starsAmountMantissa <=
                votingRound.totalStarsEntered[_msgSender][id],
            "Not enough Stars to remove"
        );
        require(
            votingRound.votingRoundState == VotingRoundState.Active,
            "Can only remove vote in active rounds"
        );

        require(
            votingRound.startVoteBlockNum <= block.number &&
                block.number <= votingRound.endVoteBlockNum,
            "Voting round has not started or ended"
        );

        uint256 oldQuadraticVoteScore = Sqrt.sqrt(
            votingRound.totalStarsEntered[_msgSender][id] / 1 ether
        );

        votingRound.totalStarsEntered[_msgSender][id] =
            votingRound.totalStarsEntered[_msgSender][id] -
            starsAmountMantissa;

        uint256 updatedUserTotalStarsEntered = votingRound.totalStarsEntered[
            _msgSender
        ][id];

        votingMasterChef.withdrawPartial(
            roundId,
            starsAmountMantissa,
            _msgSender
        );

        votingRound.votes[id] =
            votingRound.votes[id] +
            Sqrt.sqrt(updatedUserTotalStarsEntered / 1 ether) -
            oldQuadraticVoteScore;

        emit Unvoted(
            _msgSender,
            roundId,
            id,
            starsAmountMantissa,
            Sqrt.sqrt(updatedUserTotalStarsEntered / 1 ether)
        );
    }

    function calculateStarsRewards(address userAddress, uint256 roundId)
        external
        view
        votingRoundMustExist(roundId)
        returns (uint256)
    {
        return votingMasterChef.pendingStars(roundId, userAddress);
    }

    /**
     * @dev Withdraw deposited Stars and claim Stars rewards for a given
     * voting round.
     *
     * Parameters:
     *
     * - roundId: voting round id.
     * - isMogulSmartWallet: Whether or not smart wallet is used.
     * - mogulSmartWallet: address of the smart wallet, Zero address is passed if not used.
     *
     * Requirements:
     *
     * - Rewards has not been claimed.
     */
    function withdrawAndClaimStarsRewards(
        uint256 roundId,
        bool isMogulSmartWallet,
        address mogulSmartWalletAddress
    ) external votingRoundMustExist(roundId) {
        address _msgSender = _verifySmartWalletOwner(
            isMogulSmartWallet,
            mogulSmartWalletAddress,
            msgSender()
        );

        VotingRound storage votingRound = votingRounds[roundId];

        require(
            !votingRound.rewardsClaimed[_msgSender],
            "Rewards have already been claimed"
        );

        votingRound.rewardsClaimed[_msgSender] = true;

        votingMasterChef.withdraw(roundId, _msgSender);
    }

    /**
     * @dev Withdraw deposited ETH.
     *
     * Requirements:
     *
     * - Withdrawer must be an admin
     */
    function withdrawETH() external onlyAdmin {
        payable(msgSender()).transfer(address(this).balance);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;

contract BasicMetaTransaction {
  event MetaTransactionExecuted(
    address userAddress,
    address payable relayerAddress,
    bytes functionSignature
  );
  mapping(address => uint256) private nonces;

  function getChainID() public view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
   * Main function to be called when user wants to execute meta transaction.
   * The actual function to be called should be passed as param with name functionSignature
   * Here the basic signature recovery is being used. Signature is expected to be generated using
   * personal_sign method.
   * @param userAddress Address of user trying to do meta transaction
   * @param functionSignature Signature of the actual function to be called via meta transaction
   * @param sigR R part of the signature
   * @param sigS S part of the signature
   * @param sigV V part of the signature
   */
  function executeMetaTransaction(
    address userAddress,
    bytes calldata functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) external payable returns (bytes memory) {
    require(
      verify(
        userAddress,
        nonces[userAddress],
        getChainID(),
        functionSignature,
        sigR,
        sigS,
        sigV
      ),
      "Signer and signature do not match"
    );
    nonces[userAddress] = nonces[userAddress] + 1;

    // Append userAddress at the end to extract it from calling context
    (bool success, bytes memory returnData) = address(this).call(
      abi.encodePacked(functionSignature, userAddress)
    );

    require(success, "Function call not successful");
    emit MetaTransactionExecuted(
      userAddress,
      payable(msg.sender),
      functionSignature
    );
    return returnData;
  }

  function getNonce(address user) external view returns (uint256 nonce) {
    nonce = nonces[user];
  }

  // Builds a prefixed hash to mimic the behavior of eth_sign.
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  function verify(
    address owner,
    uint256 nonce,
    uint256 chainID,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public view returns (bool) {
    bytes32 hash = prefixed(
      keccak256(abi.encodePacked(nonce, this, chainID, functionSignature))
    );
    address signer = ecrecover(hash, sigV, sigR, sigS);
    require(signer != address(0), "Invalid signature");
    return (owner == signer);
  }

  function msgSender() internal view returns (address sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      return msg.sender;
    }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMogulSmartWallet {
    function owner() external returns (address);

    function initialize(
        address _owner,
        address[] calldata _guardians,
        uint256 _minGuardianVotesRequired,
        uint256 _pausePeriod
    ) external;

    function addGuardians(address[] calldata newGuardians) external;

    function removeGuardians(address[] calldata newGuardians) external;

    function getGuardiansAmount() external view returns (uint256);

    function getAllGuardians() external view returns (address[100] memory);

    function isGuardian(address accountAddress) external view returns (bool);

    function changeOwnerByOwner(address newOwner) external;

    function createChangeOwnerProposal(address newOwner) external;

    function addVoteChangeOwnerProposal() external;

    function removeVoteChangeOwnerProposal() external;

    function changeOwnerByGuardian() external;

    function setMinGuardianVotesRequired(uint256 _minGuardianVotesRequired)
        external;

    function approveERC20(
        address erc20Address,
        address spender,
        uint256 amt
    ) external;

    function transferERC20(
        address erc20Address,
        address recipient,
        uint256 amt
    ) external;

    function transferFromERC20(
        address erc20Address,
        address sender,
        address recipient,
        uint256 amt
    ) external;

    function transferFromERC721(
        address erc721Address,
        address sender,
        address recipient,
        uint256 tokenId
    ) external;

    function safeTransferFromERC721(
        address erc721Address,
        address sender,
        address recipient,
        uint256 tokenId
    ) external;

    function safeTransferFromERC721(
        address erc721Address,
        address sender,
        address recipient,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function approveERC721(
        address erc721Address,
        address spender,
        uint256 tokenId
    ) external;

    function setApprovalForAllERC721(
        address erc721Address,
        address operator,
        bool approved
    ) external;

    function safeTransferFromERC1155(
        address erc1155Address,
        address sender,
        address recipient,
        uint256 tokenId,
        uint256 amt,
        bytes calldata data
    ) external;

    function safeBatchTransferFromERC1155(
        address erc1155Address,
        address sender,
        address recipient,
        uint256[] calldata tokenIds,
        uint256[] calldata amts,
        bytes calldata data
    ) external;

    function setApprovalForAllERC1155(
        address erc1155Address,
        address operator,
        bool approved
    ) external;

    function transferNativeToken(address payable recipient, uint256 amt)
        external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IVotingMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 lastRewardBlock; // Last block number that Stars distribution occurs.
        uint256 accStarsPerShare; // Accumulated Stars per share, times ACC_SUSHI_PRECISION. See below.
        uint256 poolSupply;
        uint256 rewardAmount;
        uint256 rewardAmountPerBlock;
        uint256 startBlock;
        uint256 endBlock;
    }

    function userInfo(uint256 pid, address user)
        external
        returns (uint256, uint256);

    function init(address _votingAddress) external;

    function poolLength() external returns (uint256);

    function add(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _rewardAmount,
        bool _withUpdate
    ) external;

    function pendingStars(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function accStarsPerShareAtCurrRate(
        uint256 blocks,
        uint256 rewardAmountPerBlock,
        uint256 poolSupply,
        uint256 startBlock,
        uint256 endBlock
    ) external returns (uint256);

    function starsPerBlock(uint256 pid) external returns (uint256);

    function updatePool(uint256 _pid) external;

    function massUpdatePools() external;

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _staker
    ) external;

    function withdraw(uint256 _pid, address _staker) external;

    function withdrawPartial(
        uint256 _pid,
        uint256 _amount,
        address _staker
    ) external;

    function emergencyWithdraw(uint256 _pid, address _staker) external;

    function safeStarsTransfer(address _to, uint256 _amount) external;
}

pragma solidity ^0.8.0;

library Sqrt {
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Calculate the square root of the perfect square of a power of two that is the closest to x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1; // Seven iterations should be enough
        uint256 roundedDownResult = x / result;
        return result >= roundedDownResult ? roundedDownResult : result;
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