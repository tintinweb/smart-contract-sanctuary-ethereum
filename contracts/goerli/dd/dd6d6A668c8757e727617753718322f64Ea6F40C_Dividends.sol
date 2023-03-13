// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IDividends.sol";
import "./RestrictedLockupToken.sol";
import "./EasyAccessControl.sol";

contract Dividends is IDividends, EasyAccessControl, ReentrancyGuard {
    RestrictedLockupToken public restrictedLockupToken;

    using SafeERC20 for IERC20;

    /// @dev tokens -> security tokens; funds -> ERC20 tokens used for dividends
    struct FundedDividends {
        uint256 initialFunds; // Initial amount of dividend tokens funded
        uint256 totalFunds; // Total dividend tokens
        uint256 unusedFunds; // Unused dividend tokens
        uint256 adjustedClaimedFunds; // Total dividends already claimed; scaled by adjustedScalingFactor to account for changes to proportional share
        uint256 adjustedScalingFactor; // Accounts for situations of multiple funded dividends per snapshot, and its changes to proportional awarded balance
    }

    /// @dev snapshotID => token => receiver => amount of claimed dividend funds
    mapping(uint256 => mapping(address => mapping(address => uint256))) claimedFunds; // claimed dividend funds of ERC20
    /// @dev snapshotID => token => receiver => scaled amount of claimed dividend funds
    mapping(uint256 => mapping(address => mapping(address => uint256))) adjustedClaimedFundsPerUser; // claimed dividend funds of ERC20; scaled by the adjustedScalingFactor

    /// @dev snapshotID => token addr => FundedDividends struct
    mapping(uint256 => mapping(address => FundedDividends)) fundedDividends;

    /// @dev Accuracy of division
    uint256 public immutable TOKEN_PRECISION_DIVIDER;

    constructor(
        address contractAdmin_,
        address tokenTransferAdmin_,
        address restrictedLockupTokenAddress_
    ) ReentrancyGuard() EasyAccessControl(contractAdmin_) {
        require(
            tokenTransferAdmin_ != address(0),
            "Cannot set 0x0 as tokenTransferAdmin"
        );
        require(
            restrictedLockupTokenAddress_ != address(0),
            "Cannot set 0x0 as restrictedLockupTokenAddress"
        );

        setupRole(tokenTransferAdmin_, TRANSFER_ADMIN_ROLE);

        restrictedLockupToken = RestrictedLockupToken(
            restrictedLockupTokenAddress_
        );

        TOKEN_PRECISION_DIVIDER = 10 ** restrictedLockupToken.decimals();
    }

    modifier onlyValidSnapshot(uint256 snapshotID) {
        require(snapshotID > 0, "Snapshot ID must be greater than 0");
        require(
            snapshotID <= restrictedLockupToken.getCurrentSnapshotId(),
            "Snapshot ID must be less than or equal to current snapshot ID"
        );
        _;
    }

    /// @inheritdoc IDividends
    function batchClaimDividend(
        address token,
        uint256[] calldata snapshotIds
    ) external override {
        uint256 _snapshotIdsLength = snapshotIds.length;
        for (uint256 i; i < _snapshotIdsLength; ) {
            claimDividend(token, snapshotIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IDividends
    function claimedBalanceAt(
        address token,
        address receiver,
        uint256 snapshotId
    ) public view override returns (uint256) {
        return claimedFunds[snapshotId][token][receiver];
    }

    /// @dev Calculate current adjustedClaimed balance of receiver in security tokens mul by adjustedScalingFactor
    /// Added to reduce gas cost
    function _adjustedClaimedBalanceAt(
        address token,
        address receiver,
        uint256 snapshotId
    ) private view returns (uint256) {
        return
            restrictedLockupToken.balanceOfAt(receiver, snapshotId) *
            fundedDividends[snapshotId][token].adjustedScalingFactor -
            adjustedClaimedFundsPerUser[snapshotId][token][receiver];
    }

    /// @inheritdoc IDividends
    function claimDividend(
        address token,
        uint256 snapshotId
    ) public override nonReentrant onlyValidSnapshot(snapshotId) {
        uint256 unclaimedBalance = unclaimedBalanceAt(
            token,
            msg.sender,
            snapshotId
        );

        require(unclaimedBalance > 0, "You can't receive more tokens");

        claimedFunds[snapshotId][token][msg.sender] += unclaimedBalance;
        fundedDividends[snapshotId][token].unusedFunds -= unclaimedBalance;

        uint256 _adjustedClaimedBalance = _adjustedClaimedBalanceAt(
            token,
            msg.sender,
            snapshotId
        );

        // Update states
        fundedDividends[snapshotId][token]
            .adjustedClaimedFunds += _adjustedClaimedBalance;
        adjustedClaimedFundsPerUser[snapshotId][token][
            msg.sender
        ] += _adjustedClaimedBalance;

        emit Claimed(msg.sender, token, unclaimedBalance, snapshotId);

        IERC20(token).safeTransfer(msg.sender, unclaimedBalance);
    }

    /**
     * @dev Fund any ERC20 tokens into current contract
     * Tokens can be claimed by holders of RestrictedSwap Token uses claimDividends method
     * @param token ERC20 token address
     * @param amount amount of tokens to fund
     * @param snapshotId snapshot ID of RestrictedSwap Token
     */
    function fundDividend(
        address token,
        uint256 amount,
        uint256 snapshotId
    )
        external
        override
        nonReentrant
        onlyTransferAdmin
        onlyValidSnapshot(snapshotId)
    {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be > 0");

        IERC20 paymentToken = IERC20(token);

        fundedDividends[snapshotId][token].unusedFunds += amount;
        fundedDividends[snapshotId][token].totalFunds += amount;

        /// @notice before adjustedScalingFactor has been defined; ie no initialFunds
        if (fundedDividends[snapshotId][token].adjustedScalingFactor == 0) {
            fundedDividends[snapshotId][token].adjustedScalingFactor =
                1 *
                TOKEN_PRECISION_DIVIDER;
            fundedDividends[snapshotId][token].initialFunds = amount;
        } else {
            /// @notice subsequent funding rounds
            uint256 _adjustedScalingFactor0 = fundedDividends[snapshotId][token]
                .adjustedScalingFactor;
            /// @notice update scaling factor during each new funding round; proportional to initial funds
            uint256 _adjustedScalingFactor1 = _adjustedScalingFactor0 +
                (amount * TOKEN_PRECISION_DIVIDER) /
                fundedDividends[snapshotId][token].initialFunds; // initialFunds cannot be 0 because of require statement above
            fundedDividends[snapshotId][token]
                .adjustedScalingFactor = _adjustedScalingFactor1;
        }

        emit Funded(msg.sender, token, amount, snapshotId);
        uint256 _balanceBefore = IERC20(paymentToken).balanceOf(address(this));
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 _balanceAfter = IERC20(paymentToken).balanceOf(address(this));
        require(
            _balanceBefore + amount == _balanceAfter,
            "Dividend reverted for partial funding"
        );
    }

    /// @inheritdoc IDividends
    function tokensAt(
        address token,
        uint256 snapshotId
    ) external view override returns (uint256) {
        return fundedDividends[snapshotId][token].unusedFunds;
    }

    /**
     * @dev Proxy function for restricted token to retrieve totalSupply at snapshot
     * @param snapshotId Snapshot ID
     * @return totalSupply at snapshot
     */
    function totalSupplyAt(uint256 snapshotId) external view returns (uint256) {
        return restrictedLockupToken.totalSupplyAt(snapshotId);
    }

    /**
     * @dev Proxy function for restricted token to retrieve balanceOf address at snapshot
     * @param sender address to check balance
     * @param snapshotId snapshot ID
     * @return balance of address at snapshot
     */
    function balanceOfAt(
        address sender,
        uint256 snapshotId
    ) external view returns (uint256) {
        return restrictedLockupToken.balanceOfAt(sender, snapshotId);
    }

    /// @inheritdoc IDividends
    function fundsAt(
        address token,
        uint256 snapshotId
    ) external view override returns (uint256) {
        return fundedDividends[snapshotId][token].totalFunds;
    }

    /// @inheritdoc IDividends
    function totalAwardedBalanceAt(
        address token,
        address receiver,
        uint256 snapshotId
    ) public view override returns (uint256) {
        return
            unclaimedBalanceAt(token, receiver, snapshotId) +
            claimedBalanceAt(token, receiver, snapshotId);
    }

    /// @inheritdoc IDividends
    function unclaimedBalanceAt(
        address token,
        address receiver,
        uint256 snapshotId
    ) public view override returns (uint256) {
        /// @notice scaling factor required to account for multiple funding events
        uint256 _adjustedClaimedFundsPerUser = adjustedClaimedFundsPerUser[
            snapshotId
        ][token][receiver];
        uint256 _adjustedScalingFactor = fundedDividends[snapshotId][token]
            .adjustedScalingFactor;
        uint256 _adjustedSecurityTokenBalance = restrictedLockupToken
            .balanceOfAt(receiver, snapshotId) * _adjustedScalingFactor; /// @notice adjust sec token balance by scaling factor

        uint256 _remainingAdjustedClaimedFundsPerUser = _adjustedSecurityTokenBalance -
                _adjustedClaimedFundsPerUser;
        uint256 _adjustedBaseSupply = restrictedLockupToken.totalSupplyAt(
            snapshotId
        ) * _adjustedScalingFactor; /// @notice adjust total supply by scaling factor

        uint256 _adjustedTotalUnclaimedTokens = _adjustedBaseSupply -
            fundedDividends[snapshotId][token].adjustedClaimedFunds; /// @notice adjusted total unclaimed tokens for a given snapshot/token

        if (_adjustedTotalUnclaimedTokens == 0) return 0; /// @notice prevent division by zero

        return
            (_remainingAdjustedClaimedFundsPerUser *
                fundedDividends[snapshotId][token].unusedFunds) /
            _adjustedTotalUnclaimedTokens;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title Binary Access control
 * @author By CoMakery, Inc., Upside, Republic
 * @dev Binary equivalent to OpenZeppelin/AccessControl
 *  Uses bits for storing user roles, minify gas cost and contract size
 */
contract EasyAccessControl {
    uint8 public constant CONTRACT_ADMIN_ROLE = 1; // 0001
    uint8 public constant RESERVE_ADMIN_ROLE = 2; // 0010
    uint8 public constant WALLETS_ADMIN_ROLE = 4; // 0100
    uint8 public constant TRANSFER_ADMIN_ROLE = 8; // 1000

    /// @notice This event is emitted when a new role is granted or revoked to a user
    /// @param grantor The address of admin who granted the role
    /// @param grantee The address of user who received the role
    /// @param role The role that was granted as a bitmask
    /// @param status The status of the role (true = granted, false = revoked)
    event RoleChange(
        address indexed grantor,
        address indexed grantee,
        uint8 role,
        bool indexed status
    );

    mapping(address => uint8) admins; // address => binary roles

    uint8 public contractAdminCount; // counter of contract admins to keep at least one

    modifier validAddress(address addr) {
        require(addr != address(0), "Address cannot be 0x0");
        _;
    }

    modifier validRole(uint8 role) {
        require(role > 0, "Does not have valid role");
        _;
    }

    modifier onlyContractAdmin() {
        require(
            hasRole(msg.sender, CONTRACT_ADMIN_ROLE),
            "Does not have contract admin role"
        );
        _;
    }

    modifier onlyTransferAdmin() {
        require(
            hasRole(msg.sender, TRANSFER_ADMIN_ROLE),
            "Does not have transfer admin role"
        );
        _;
    }

    modifier onlyReserveAdmin() {
        require(
            hasRole(msg.sender, RESERVE_ADMIN_ROLE),
            "Does not have reserve admin role"
        );
        _;
    }

    modifier anyAdmin() {
        require(
            hasRole(msg.sender, RESERVE_ADMIN_ROLE) ||
                hasRole(msg.sender, WALLETS_ADMIN_ROLE) ||
                hasRole(msg.sender, TRANSFER_ADMIN_ROLE) ||
                hasRole(msg.sender, CONTRACT_ADMIN_ROLE),
            "Not admin"
        );
        _;
    }

    /**
     * @notice Constructor, init base role
     * @param contractAdmin_ address of contract admin
     */
    constructor(address contractAdmin_) validAddress(contractAdmin_) {
        setupRole(contractAdmin_, CONTRACT_ADMIN_ROLE);
    }

    /**
     * @notice Grant role/roles to address using role bitmask
     * @param addr to grant role
     * @param role bitmask of role/roles to grant
     */
    function grantRole(
        address addr,
        uint8 role
    ) public validRole(role) validAddress(addr) onlyContractAdmin {
        _grantRole(addr, role);
        emit RoleChange(msg.sender, addr, role, true);
    }

    /**
     * @notice Grant role/roles to address using role bitmask
     * @param addr to grant role
     *  @param role bitmask of role/roles to grant
     */
    function _grantRole(address addr, uint8 role) internal virtual {
        require(admins[addr] & role != role, "Already has role");
        if (
            admins[addr] & CONTRACT_ADMIN_ROLE == 0 &&
            role & CONTRACT_ADMIN_ROLE > 0
        ) contractAdminCount++;
        admins[addr] |= role;
    }

    /**
     * @notice Initialize role/roles to address using role bitmask
     * @param addr to grant role
     * @param role bitmask of role/roles to grant
     */
    function setupRole(address addr, uint8 role) internal {
        if (
            admins[addr] & CONTRACT_ADMIN_ROLE == 0 &&
            role & CONTRACT_ADMIN_ROLE > 0
        ) contractAdminCount++;
        admins[addr] |= role;
        emit RoleChange(msg.sender, addr, role, true);
    }

    /**
     * @notice Revoke role/roles from address using role bitmask
     * @param addr to revoke role
     * @param role bitmask of role/roles to revoke
     */
    function revokeRole(
        address addr,
        uint8 role
    ) public validRole(role) validAddress(addr) onlyContractAdmin {
        require(hasRole(addr, role), "Can not revoke role");
        if (role & CONTRACT_ADMIN_ROLE > 0) {
            require(
                contractAdminCount > 1,
                "Must have at least one contract admin"
            );
            contractAdminCount--;
        }
        admins[addr] ^= role;
        emit RoleChange(msg.sender, addr, role, false);
    }

    /**
     * @notice Check role/roles availability at address
     * @param addr to check role
     * @param role bitmask of role/roles to check
     * @return bool true or false
     */
    function hasRole(
        address addr,
        uint8 role
    ) public view validRole(role) validAddress(addr) returns (bool) {
        return admins[addr] & role == role;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/ITransferRules.sol";
import "./EasyAccessControl.sol";
import "./interfaces/IERC1404.sol";

/**
  @title A smart contract for unlocking tokens based on a release schedule
  @author By CoMakery, Inc., Upside, Republic
  @dev When deployed the contract is as a proxy for a single token that it creates release schedules for
      it implements the ERC20 token interface to integrate with wallets but it is not an independent token.
      The token must implement a burn function.
*/
contract RestrictedLockupToken is
    ERC20Snapshot,
    EasyAccessControl,
    ReentrancyGuard,
    ERC165
{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct ReleaseSchedule {
        uint256 releaseCount;
        uint256 delayUntilFirstReleaseInSeconds;
        uint256 initialReleasePortionInBips;
        uint256 periodBetweenReleasesInSeconds;
    }

    struct Timelock {
        address funder;
        uint256 scheduleId;
        uint256 commencementTimestamp;
        uint256 tokensTransferred;
        uint256 totalAmount;
        address[] cancelableBy; // not cancelable unless set at the time of funding
    }

    ReleaseSchedule[] public releaseSchedules;
    Counters.Counter private _holderIds; // starts at 1 for 1st holder

    ITransferRules public transferRules;

    mapping(address => Timelock[]) public timelocks; // wallet address => timelock details
    mapping(uint256 => int256) public holderGroupCount; // groupId => current holders count
    mapping(uint256 => int256) public holderGroupMax; // groupId => max holders
    mapping(address => bool) private _frozenAddresses; // address => isFrozen
    mapping(address => uint256) private _holderIdByAddress; // wallet address => holderId
    mapping(uint256 => address[]) private _holderAddressesByHolderId; // holderId => wallet addresses
    mapping(address => uint256) private _transferGroups; // wallet address => groupId, restricted groups like Reg D Accredited US, Reg CF Unaccredited US and Reg S Foreign
    mapping(uint256 => mapping(uint256 => uint256))
        private _allowGroupTransfers; // approve transfers between groups: groupFromId => groupToId => TimeLockUntil

    uint256 public immutable minTimelockAmount;
    uint256 public immutable maxReleaseDelay;
    uint256 public immutable maxTotalSupply;
    int256 public holderMax = 2 ** 255 - 1; // Maximum uint256 value - walletsMax
    int256 public holderCount; // walletsCount
    uint256 public minWalletBalance; // minimum balance for automatic group leaving
    uint8 private immutable _decimals;
    uint256 private constant BIPS_PRECISION = 10_000;
    uint256 private constant MAX_TIMELOCKS = 10_000;

    uint8 constant MAX_CANCELABLE_BY = 10; // maximum number of addresses that can cancel a timelock

    bool public isPaused;

    bytes4 public immutable _ITRANSFER_RULES_INTERFACE_ID;

    /// @notice This event is emitted when a new release schedule is created
    /// @param from The address of the schedule creator
    /// @param scheduleId The id of the new release schedule
    event ScheduleCreated(address indexed from, uint256 indexed scheduleId);

    /// @notice This event is emitted when a schedule is funded
    /// @param from The address of the funder
    /// @param to The address of the recipient of the tokens when schedule is released
    /// @param scheduleId The id of the release schedule
    /// @param amount The amount of tokens to be released
    /// @param commencementTimestamp The timestamp when the release schedule starts
    /// @param timelockId The id of the timelock
    /// @param cancelableBy The addresses that can cancel the timelock
    event ScheduleFunded(
        address indexed from,
        address indexed to,
        uint256 indexed scheduleId,
        uint256 amount,
        uint256 commencementTimestamp,
        uint256 timelockId,
        address[] cancelableBy
    );

    /// @notice This event is emitted when a timelock is canceled
    /// @param canceledBy The address of the canceller
    /// @param target The address of the recipient of the unlocked tokens
    /// @param timelockIndex The index of the timelock in the timelocks array
    /// @param reclaimTokenTo The address of the recipient of the locked tokens
    /// @param canceledAmount The total amount of canceled tokens
    /// @param paidAmount The amount of paid tokens to target
    event TimelockCanceled(
        address indexed canceledBy,
        address indexed target,
        uint256 indexed timelockIndex,
        address reclaimTokenTo,
        uint256 canceledAmount,
        uint256 paidAmount
    );

    /// @notice This event is emitted when a address is frozen or unfrozen
    /// @param admin The address of the admin
    /// @param addr The (un)frozen address
    /// @param status true - frozen, false - unfrozen
    event AddressFrozen(
        address indexed admin,
        address indexed addr,
        bool indexed status
    );

    /// @notice This event is emitted when a contract is paused or unpaused
    /// @param admin The address of the admin
    /// @param status true - paused, false - unpaused
    event Pause(address indexed admin, bool indexed status);

    /// @notice This event is emitted when a transfer group is updated
    /// @param admin The address of the admin
    /// @param oldRules The old transfer rules contract address
    /// @param newRules The new transfer rules contract address
    event Upgrade(
        address indexed admin,
        address indexed oldRules,
        address indexed newRules
    );

    /// @notice This event is emitted when a address transfer group is updated
    /// @param admin The address of the admin
    /// @param addr The address of the wallet
    /// @param value The new address's transfer group id
    event AddressTransferGroup(
        address indexed admin,
        address indexed addr,
        uint256 indexed value
    );

    /// @notice This event is emitted when an allowed transfer between groups after lockedUntil
    /// @param admin The address of the admin
    /// @param fromGroup The id of the group to transfer from
    /// @param toGroup The id of the group to transfer to
    /// @param lockedUntil The timestamp after which the transfer is allowed
    event AllowGroupTransfer(
        address indexed admin,
        uint256 indexed fromGroup,
        uint256 indexed toGroup,
        uint256 lockedUntil
    );

    /// @notice This event is emitted when a force transfer between wallets is executed by admin
    /// @param admin The address of the admin
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param amount The amount of tokens to transfer
    event ForceTransferBetween(
        address indexed admin,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /// @notice This event is emitted when an append new wallet address to existing holder
    /// @param addr The address of the wallet
    /// @param holderId The id of the holder
    event AppendHolderAddress(address indexed addr, uint256 indexed holderId);

    /// @notice This event is emitted when an updated holder max limit
    /// @param admin The address of the admin
    /// @param holderMax The new holder max limit
    event SetHolderMax(address indexed admin, int256 holderMax);

    /// @notice This event is emitted when an updated group holder max limit
    /// @param admin The address of the admin
    /// @param groupId The id of the group
    /// @param groupHolderMax The new group holder max limit
    event SetHolderGroupMax(
        address indexed admin,
        uint256 indexed groupId,
        int256 groupHolderMax
    );

    /// @notice This event is emitted when a holder is removed
    /// @param admin The address of the admin
    /// @param holderId The id of the holder
    event RemoveHolder(address indexed admin, uint256 indexed holderId);

    /// @notice This event is emitted when a holder is created
    /// @param holderId The id of the holder
    /// @param addr The primary address of the holder
    event HolderCreated(uint256 indexed holderId, address indexed addr);

    /// @notice This event is emitted when a minimum wallet balance is updated
    /// @param admin The address of the admin
    /// @param newBalance The new minimum wallet balance to be in a group
    event MinWalletBalanceUpdated(address indexed admin, uint256 newBalance);

    modifier onlyWalletsAdminOrTransferAdmin() {
        require(
            (hasRole(msg.sender, WALLETS_ADMIN_ROLE) ||
                hasRole(msg.sender, TRANSFER_ADMIN_ROLE)),
            "Does not have wallets admin or transfer admin role"
        );
        _;
    }

    modifier onlyExistingAddress(address addr) {
        require(addressHasHolder(addr), "Holder's address does not exist");
        _;
    }

    modifier onlyExistingHolder(uint256 holderId) {
        require(holderExists(holderId), "Holder does not exist");
        _;
    }

    /**
     * @dev Configure deployment for a specific token with release schedule security parameters
     * @dev The symbol should end with " Unlock" & be less than 11 characters for MetaMask "custom token" compatibility
     */
    constructor(
        address transferRules_,
        address contractAdmin_,
        address tokenReserveAdmin_,
        string memory symbol_,
        string memory name_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 maxTotalSupply_,
        uint256 minTimelockAmount_,
        uint256 maxReleaseDelay_
    ) ERC20(name_, symbol_) ERC20Snapshot() EasyAccessControl(contractAdmin_) {
        // Restricted Token
        require(bytes(name_).length > 0, "Name cannot be empty");
        require(bytes(symbol_).length > 0, "Symbol cannot be empty");
        require(
            totalSupply_ <= maxTotalSupply_,
            "Total supply cannot be greater than max total supply"
        );
        require(
            transferRules_ != address(0),
            "Transfer rules address cannot be 0x0"
        );
        require(
            tokenReserveAdmin_ != address(0),
            "Token reserve admin address cannot be 0x0"
        );

        // Transfer rules can be swapped out for a new contract inheriting from the ITransferRules interface
        transferRules = ITransferRules(transferRules_);
        _ITRANSFER_RULES_INTERFACE_ID = type(ITransferRules).interfaceId;

        maxTotalSupply = maxTotalSupply_;
        _decimals = decimals_;

        minWalletBalance = 10 ** decimals_; // == 1 whole unit

        setupRole(tokenReserveAdmin_, RESERVE_ADMIN_ROLE);

        _mint(tokenReserveAdmin_, totalSupply_);

        // Token Lockup
        require(minTimelockAmount_ > 0, "Min timelock amount > 0");
        minTimelockAmount = minTimelockAmount_;
        maxReleaseDelay = maxReleaseDelay_;
    }

    /**
     * Support of ERC165
     * @dev See https://eips.ethereum.org/EIPS/eip-165
     * @param interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC1404).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev update minWalletBalance; onlyTransferAdmin
     * @param minWalletBalance_ The min allowable balance across all groups
     */
    function setMinWalletBalance(
        uint256 minWalletBalance_
    ) external onlyTransferAdmin {
        minWalletBalance = minWalletBalance_;
        emit MinWalletBalanceUpdated(msg.sender, minWalletBalance_);
    }

    /**
     * @notice Create a release schedule template that can be used to generate many token timelocks
     * @param releaseCount Total number of releases including any initial "cliff'
     * @param delayUntilFirstReleaseInSeconds "cliff" or 0 for immediate release
     * @param initialReleasePortionInBips Portion to release in 100ths of 1% (10000 BIPS per 100%)
     * @param periodBetweenReleasesInSeconds After the delay and initial release
     * the remaining tokens will be distributed evenly across the remaining number of releases (releaseCount - 1)
     * @return unlockScheduleId The id used to refer to the release schedule at the time of funding the schedule
     */
    function createReleaseSchedule(
        uint256 releaseCount,
        uint256 delayUntilFirstReleaseInSeconds,
        uint256 initialReleasePortionInBips,
        uint256 periodBetweenReleasesInSeconds
    ) external anyAdmin returns (uint256 unlockScheduleId) {
        require(
            delayUntilFirstReleaseInSeconds <= maxReleaseDelay,
            "First token release delay time > max allowable"
        );
        require(releaseCount >= 1, "Must have >= 1 release");
        require(
            initialReleasePortionInBips <= BIPS_PRECISION,
            "Initial release portion > BIPS_PRECISION (100%)"
        );

        if (releaseCount > 1) {
            require(
                periodBetweenReleasesInSeconds > 0,
                "Release period must be > 0"
            );
        } else {
            require(
                initialReleasePortionInBips == BIPS_PRECISION,
                "Initial release portion must = BIPS_PRECISION (100%) for single release"
            );
            periodBetweenReleasesInSeconds = 0;
        }

        releaseSchedules.push(
            ReleaseSchedule(
                releaseCount,
                delayUntilFirstReleaseInSeconds,
                initialReleasePortionInBips,
                periodBetweenReleasesInSeconds
            )
        );

        unlockScheduleId = releaseSchedules.length - 1;
        emit ScheduleCreated(msg.sender, unlockScheduleId);

        return unlockScheduleId;
    }

    /**
     * @dev batchTransfer tokens
     */
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external returns (bool) {
        uint256 _recipientsLength = recipients.length;
        require(
            _recipientsLength == amounts.length,
            "Recipient & amount arrays must be the same length"
        );
        for (uint256 i; i < _recipientsLength; ++i) {
            address _recipient = recipients[i];
            require(_recipient != address(0), "Cannot send to 0 address");
            transfer(_recipient, amounts[i]);
        }

        return true;
    }

    /**
     * @dev Allows the contract admin to upgrade the transfer rules.
     * The upgraded transfer rules must implement the ITransferRules interface which conforms to the ERC-1404 token standard.
     * @param newTransferRules The address of the deployed TransferRules contract.
     */
    function upgradeTransferRules(
        ITransferRules newTransferRules
    ) external onlyContractAdmin {
        address _newTransferRulesAddress = address(newTransferRules);
        require(
            _newTransferRulesAddress != address(0),
            "Address cannot be 0x0"
        );
        require(
            IERC165(_newTransferRulesAddress).supportsInterface(
                _ITRANSFER_RULES_INTERFACE_ID
            ),
            "New transfer rules contract does not implement ITransferRules"
        );
        address oldRules = address(transferRules);

        transferRules = newTransferRules;
        emit Upgrade(msg.sender, oldRules, _newTransferRulesAddress);
    }

    /**
     *  @notice Batch version of fund cancelable release schedule
     *  @param to An array of recipient address that will have tokens unlocked on a release schedule
     *  @param amounts An array of amount of tokens to transfer in base units (the smallest unit without the decimal point)
     *  @param commencementTimestamps An array of the time the release schedule will start
     *  @param scheduleIds An array of the id of the release schedule that will be used to release the tokens
     *  @param cancelableBy An array of cancelables
     *  @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
     */
    function batchFundReleaseSchedule(
        address[] calldata to,
        uint256[] calldata amounts,
        uint256[] calldata commencementTimestamps,
        uint256[] calldata scheduleIds,
        address[] calldata cancelableBy
    ) external anyAdmin returns (bool success) {
        require(
            to.length == amounts.length &&
                to.length == commencementTimestamps.length &&
                to.length == scheduleIds.length,
            "Mismatched array length"
        );

        for (uint256 i; i < to.length; ++i) {
            require(
                fundReleaseSchedule(
                    to[i],
                    amounts[i],
                    commencementTimestamps[i],
                    scheduleIds[i],
                    cancelableBy
                ),
                "Can not release schedule"
            );
        }

        return true;
    }

    /**
     * @dev Transfer tokens from one address to another with ignoring of transfer rules
     * With reserve admin access only
     * @param sender sender address
     * @param recipient recipient address
     * @param amount amount of tokens
     */
    function forceTransferBetween(
        address sender,
        address recipient,
        uint256 amount
    ) external onlyReserveAdmin {
        require(sender != recipient, "Sender cannot be recipient");
        require(
            addressHasHolder(recipient),
            "Recipient must be an existing holder"
        );
        require(
            recipient != address(0) && sender != address(0),
            "Address cannot be 0x0"
        );
        require(amount > 0, "Amount must be greater than 0");

        uint256[2] memory values = validateTransfer(sender, amount);

        require(values[0] + values[1] >= amount, "Insufficent tokens");

        emit ForceTransferBetween(msg.sender, sender, recipient, amount);

        if (values[0] > 0) {
            // unlocked tokens
            super._transfer(address(this), recipient, values[0]);
        }

        if (values[1] > 0) {
            // simple tokens transfer
            super._transfer(sender, recipient, values[1]);
        }
    }

    /**
     * @dev A convenience method for updating the transfer group, lock until, and freeze status.
     * @notice This function has a different signature than the Utility Token implementation
     * @param buyerAddr_ The wallet address to set permissions for.
     * @param groupId_ The desired groupId to set for the address.
     * @param freezeStatus_ The frozenAddress status of the address. True means frozen false means not frozen.
     */
    function setAddressPermissions(
        address buyerAddr_,
        uint256 groupId_,
        bool freezeStatus_
    ) external validAddress(buyerAddr_) onlyWalletsAdminOrTransferAdmin {
        setTransferGroup(buyerAddr_, groupId_, true);
        freeze(buyerAddr_, freezeStatus_);
    }

    /**
     * @dev Destroys tokens and removes them from the total supply. Can only be called by an address with a Reserve Admin role.
     * @notice DOES NOT ACTUALLY TRANSFER TOKENS TO 0X0! Merely emits Transfer event and calls _afterTokenTransfer with recipient artificially set to 0x0.
     * @param from_ The address to destroy the tokens from.
     * @param value_ The number of tokens to destroy from the address.
     */
    function burn(
        address from_,
        uint256 value_
    ) external validAddress(from_) onlyReserveAdmin {
        _burn(from_, value_);
    }

    /**
     * @dev Allows the reserve admin to create new tokens in a specified address.
     * The total number of tokens cannot exceed the maxTotalSupply (the "Hard Cap").
     * @param to_ The addres to mint tokens into.
     * @param value_ The number of tokens to mint.
     */
    function mint(
        address to_,
        uint256 value_
    ) external validAddress(to_) onlyReserveAdmin {
        require(
            totalSupply() + value_ <= maxTotalSupply,
            "Cannot mint more than the max total supply"
        );
        _mint(to_, value_);
    }

    /**
     * @dev Sets an allowed transfer from a group to another group beginning at a specific time.
     * There is only one definitive rule per from and to group.
     * @param from The group the transfer is coming from.
     * @param to The group the transfer is going to.
     * @param lockedUntil The unix timestamp that the transfer is locked until. 0 is a special number. 0 means the transfer is not allowed.
     * This is because in the smart contract mapping all pairs are implicitly defined with a default lockedUntil value of 0.
     * But no transfers should be authorized until explicitly allowed. Thus 0 must mean no transfer is allowed.
     */
    function setAllowGroupTransfer(
        uint256 from,
        uint256 to,
        uint256 lockedUntil
    ) external onlyTransferAdmin {
        _allowGroupTransfers[from][to] = lockedUntil;
        emit AllowGroupTransfer(msg.sender, from, to, lockedUntil);
    }

    /**
     * @dev Allows the contract admin to pause transfers.
     * @param isPaused_ true to pause
     */
    function pause(bool isPaused_) external onlyTransferAdmin {
        isPaused = isPaused_;
        emit Pause(msg.sender, isPaused_);
    }

    /**
     * @dev Create new snapshot. onlyContractAdmin access
     * @return uint256 snapshot
     */
    function snapshot() external onlyContractAdmin returns (uint256) {
        return _snapshot();
    }

    /**
     * @notice the total number of schedules that have been created
     * @return count of schedules
     */
    function scheduleCount() external view returns (uint256 count) {
        return releaseSchedules.length;
    }

    /**
     * @dev Checks the status of an address to see if its frozen
     * @param addr The address to check
     * @return status Returns true if the address is frozen and false if its not frozen.
     */
    function getFrozenStatus(address addr) external view returns (bool status) {
        return _frozenAddresses[addr];
    }

    /**
     * @dev Gets the transfer group the address belongs to. The default group is 0.
     * @param addr The address to check.
     * @return groupId The group Id of the address.
     */
    function getTransferGroup(
        address addr
    ) external view returns (uint256 groupId) {
        return _transferGroups[addr];
    }

    /**
     * @dev find all holder balance
     * @param holderId_ id of holder to check
     * @return _balance balance of holder
     */
    function holderBalance(
        uint256 holderId_
    ) external view onlyExistingHolder(holderId_) returns (uint256 _balance) {
        address[] storage addresses = _holderAddressesByHolderId[holderId_];
        uint256 _len = addresses.length;
        for (uint256 i = 0; i < _len; ++i) {
            _balance += balanceOf(addresses[i]);
        }
    }

    /**
     * @dev get allowed transfer time between two addresses
     * @param from The address the transfer is coming from
     * @param to The address the transfer is going to
     * @return timestamp The Unix timestamp of the time the transfer would be allowed. A 0 means never.
     * The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
     */
    function getAllowTransferTime(
        address from,
        address to
    ) external view returns (uint256 timestamp) {
        return _allowGroupTransfers[_transferGroups[from]][_transferGroups[to]];
    }

    /**
     * @dev Checks to see when a transfer between two groups would be allowed.
     * @param from Group ID from
     * @param to Group ID to
     * @return timestamp The Unix timestamp of the time the transfer would be allowed. A 0 means never.
     * The format is the number of seconds since the Unix epoch of 00:00:00 UTC on 1 January 1970.
     */
    function getAllowGroupTransferTime(
        uint256 from,
        uint256 to
    ) external view returns (uint256 timestamp) {
        return _allowGroupTransfers[from][to];
    }

    /**
     * @dev Get current snapshot ID
     */
    function getCurrentSnapshotId() external view returns (uint256) {
        return _getCurrentSnapshotId();
    }

    /**
     * @dev Get status of address
     * @param transferRulesAddr_ The address of the new transfer rules contract
     * @return _isValidTransferRules True if the transfer rules contract is valid
     */
    function isValidTransferRules(
        address transferRulesAddr_
    ) external view virtual returns (bool) {
        return
            IERC165(transferRulesAddr_).supportsInterface(
                _ITRANSFER_RULES_INTERFACE_ID
            );
    }

    /**
     * @notice Check the total remaining balance of a timelock including the locked and unlocked portions
     * @param who the address to check
     * @param timelockIndex  Specific timelock belonging to the who address
     * @return total remaining balance of a timelock
     */
    function balanceOfTimelock(
        address who,
        uint256 timelockIndex
    ) external view returns (uint256) {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return timelock.totalAmount - timelock.tokensTransferred;
        }
    }

    /**
     * @dev find all holder balance within specified group
     * @param holderId_ id of holder to check
     * @param groupId_ transfer group id
     * @return _balance balance of holder
     */
    function holderBalanceByGroupId(
        uint256 holderId_,
        uint256 groupId_
    ) public view onlyExistingHolder(holderId_) returns (uint256 _balance) {
        address[] storage addresses = _holderAddressesByHolderId[holderId_];
        uint256 _len = addresses.length;
        for (uint256 i = 0; i < _len; ++i) {
            address _addr = addresses[i];
            if (_transferGroups[_addr] == groupId_) {
                _balance += balanceOf(_addr);
            }
        }
    }

    /**
    * @notice Fund the programmatic release of tokens to a recipient.
        WARNING: this function IS CANCELABLE by cancelableBy.
        If canceled the tokens that are locked at the time of the cancellation will be returned to the funder
        and unlocked tokens will be transferred to the recipient.
    * @param to recipient address that will have tokens unlocked on a release schedule
    * @param amount of tokens to transfer in base units (the smallest unit without the decimal point)
    * @param commencementTimestamp the time (in unixtime) the release schedule will start
    * @param scheduleId the id of the release schedule that will be used to release the tokens
    * @param cancelableBy array of canceler addresses
    * @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
    */
    function fundReleaseSchedule(
        address to,
        uint256 amount,
        uint256 commencementTimestamp, // unix timestamp
        uint256 scheduleId,
        address[] memory cancelableBy
    ) public nonReentrant anyAdmin returns (bool success) {
        require(
            cancelableBy.length <= MAX_CANCELABLE_BY,
            "Max 10 cancelableBy addressees"
        );
        require(
            amount + superBalanceOf(to) >= minWalletBalance,
            "Resulting balance < minWalletBalance"
        );

        uint256 timelockId = _fund(
            to,
            amount,
            commencementTimestamp,
            scheduleId,
            msg.sender
        );

        if (cancelableBy.length > 0) {
            timelocks[to][timelockId].cancelableBy = cancelableBy;
        }

        emit ScheduleFunded(
            msg.sender,
            to,
            scheduleId,
            amount,
            commencementTimestamp,
            timelockId,
            cancelableBy
        );
        return true;
    }

    /**
     * @dev create Holder from a given Address
     * @param addr_ address of holder
     * @return _holderId id of holder
     */
    function createHolderFromAddress(
        address addr_
    ) public onlyWalletsAdminOrTransferAdmin returns (uint256 _holderId) {
        _holderId = _createHolderFromAddress(addr_);
    }

    /**
     * @dev Append a new wallet to existing Holder
     * @param addr address of holder
     * @param holderId id of holder
     */
    function appendHolderAddress(
        address addr,
        uint256 holderId
    ) public onlyExistingHolder(holderId) onlyWalletsAdminOrTransferAdmin {
        require(_holderIdByAddress[addr] == 0, "Address already exists");

        uint256 _groupId; // default group is 0

        _holderIdByAddress[addr] = holderId;
        _holderAddressesByHolderId[holderId].push(addr);

        ++holderGroupCount[_groupId];

        emit AppendHolderAddress(addr, holderId);
    }

    /**
     * @dev add a Holder with multiple wallet addresses
     * @param addresses_ array of addresses
     * @return _holderId id of holder
     */
    function addHolderWithAddresses(
        address[] calldata addresses_
    ) external onlyWalletsAdminOrTransferAdmin returns (uint256 _holderId) {
        uint256 _addrLen = addresses_.length;
        require(_addrLen > 0, "Addresses array is empty");

        _holderId = createHolderFromAddress(addresses_[0]);
        // use first entry in array to create Holder with
        for (uint256 i = 1; i < _addrLen; ++i) {
            appendHolderAddress(addresses_[i], _holderId);
        }
    }

    /**
     * @dev set max number of holder addresses
     * @param holderMax_ max number of holder addresses
     */
    function setHolderMax(int256 holderMax_) external onlyTransferAdmin {
        require(
            holderMax_ >= holderCount,
            "Holder max should be >= holder count"
        );
        holderMax = holderMax_;

        emit SetHolderMax(msg.sender, holderMax_);
    }

    /**
     * @dev set max number of holder addresses within given group
     * @param groupId group id
     * @param groupHolderMax max number of holder addresses allowed within given group
     */
    function setHolderGroupMax(
        uint256 groupId,
        int256 groupHolderMax
    ) external onlyTransferAdmin {
        require(groupId > 0, "Can't set holder max for group 0");
        require(
            groupHolderMax >= holderGroupCount[groupId],
            "groupHolderMax must be gte current holderGroupCount"
        );
        holderGroupMax[groupId] = groupHolderMax;

        emit SetHolderGroupMax(msg.sender, groupId, groupHolderMax);
    }

    /**
     * @dev removeHolder from the system
     * @notice Holder could be removed if it has no active timelocks
     * @param holderId holder id
     */
    function removeHolder(
        uint256 holderId
    ) external onlyWalletsAdminOrTransferAdmin onlyExistingHolder(holderId) {
        emit RemoveHolder(msg.sender, holderId);
        address[] storage addresses = _holderAddressesByHolderId[holderId];
        uint256 len = addresses.length;
        for (uint256 i; i < len; ++i) {
            address addr = addresses[i];
            if (hasAnyGroup(addr)) {
                _leaveGroup(addr);
            }
            delete _holderIdByAddress[addr];
            delete _transferGroups[addr];
        }
        delete _holderAddressesByHolderId[holderId];
        --holderCount;
    }

    /**
     * @dev Set the one group that the address belongs to, such as a US Reg CF investor group.
     * @param addr_ The address to set the group for.
     * @param groupId_ The uint256 numeric Id of the group.
     * */
    function setTransferGroup(
        address addr_,
        uint256 groupId_,
        bool ignoreMinWalletBalance
    ) public onlyWalletsAdminOrTransferAdmin validAddress(addr_) {
        // Calculate total and group holders
        if (!addressHasHolder(addr_)) {
            createHolderFromAddress(addr_);
        }
        if (!hasGroup(addr_, groupId_)) {
            _joinGroup(addr_, groupId_, ignoreMinWalletBalance);
        }
    }

    /**
     * @dev get token decimals
     * @return decimals
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev get holder addresses by Id
     * @param holderId_ holder id
     * @return array of addresses
     */
    function getHolderAddresses(
        uint256 holderId_
    ) external view onlyExistingHolder(holderId_) returns (address[] memory) {
        return _holderAddressesByHolderId[holderId_];
    }

    /**
     * @dev getHolderId
     * @param addr_ address of holder
     * @return holder Id from address
     */
    function getHolderId(address addr_) public view returns (uint256) {
        return _holderIdByAddress[addr_];
    }

    /**
     * @dev Check if given address has a group
     * @param addr_ address
     * @return true if address has group
     */
    function hasAnyGroup(address addr_) public view returns (bool) {
        return _transferGroups[addr_] > 0;
    }

    /**
     * @dev safeApprove should only be called when setting an initial allowance,
     * or when resetting it to zero.
     * @param spender spending address to approve
     * @param value amount to approve
     */
    function safeApprove(address spender, uint256 value) external {
        require(
            (value == 0) || (allowance(address(msg.sender), spender) == 0),
            "Cannot approve from non-zero to non-zero allowance"
        );
        approve(spender, value);
    }

    /**
     * @dev check if address has holder
     * @param addr_ address to check
     * @return true if address has holder
     */
    function addressHasHolder(address addr_) public view returns (bool) {
        return _holderIdByAddress[addr_] > 0;
    }

    /**
     * @dev check if holder exists
     * @param holderId_ id of holder to check
     * @return true if holderId exists
     * */
    function holderExists(uint256 holderId_) public view returns (bool) {
        return _holderAddressesByHolderId[holderId_].length > 0;
    }

    /**
     * @dev check if address has group
     * @param addr_ address to check
     * @param groupId_ id of group to check
     * @return true if address has group
     * */
    function hasGroup(
        address addr_,
        uint256 groupId_
    ) public view returns (bool) {
        return _transferGroups[addr_] == groupId_;
    }

    /**
     * @dev Enforces transfer restrictions managed using the ERC-1404 standard functions.
     * The TransferRules contract defines what the rules are. The data inputs to those rules remains in the RestrictedToken contract.
     * TransferRules is a separate contract so its logic can be upgraded.
     * @param from The address the tokens are transferred from
     * @param to The address the tokens would be transferred to
     * @param value the quantity of tokens to be transferred
     */
    function enforceTransferRestrictions(
        address from,
        address to,
        uint256 value
    ) private view {
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(
            transferRules.checkSuccess(restrictionCode),
            messageForTransferRestriction(restrictionCode)
        );
    }

    /**
     * @dev Calls the TransferRules detectTransferRetriction function to determine if tokens can be transferred.
     * detectTransferRestriction returns a status code. ERC-1404 standard.
     * @param from The address the tokens are transferred from
     * @param to The address the tokens would be transferred to
     * @param value The quantity of tokens to be transferred
     */
    function detectTransferRestriction(
        address from,
        address to,
        uint256 value
    ) public view returns (uint8) {
        return
            transferRules.detectTransferRestriction(
                address(this),
                from,
                to,
                value
            );
    }

    /**
     * @dev Calls TransferRules to lookup a human readable error message that goes with an error code. ERC-1404 standard.
     * @param restrictionCode is an error code to lookup an error code for
     * @return a human readable error message
     */
    function messageForTransferRestriction(
        uint8 restrictionCode
    ) public view returns (string memory) {
        return transferRules.messageForTransferRestriction(restrictionCode);
    }

    /**
    * @notice ERC20 standard interface function
            Provide controls of Restricted and Lockup tokens
            Can transfer simple ERC20 tokens and unlocked tokens at the same time
            First will transfer unlocked tokens and then simple ERC20
    * @param sender of transfer
    * @param recipient of transfer
    * @param amount of tokens to transfer
    * @return true On success / Reverted on error
    */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(
            recipient != address(0) && sender != address(0),
            "Address cannot be 0x0"
        );

        uint256 currentAllowance = allowance(sender, msg.sender);

        require(
            amount <= currentAllowance,
            "The approved allowance is lower than the transfer amount"
        );
        enforceTransferRestrictions(sender, recipient, amount);

        uint256[2] memory values = validateTransfer(sender, amount);
        require(values[0] + values[1] >= amount, "Insufficent tokens");

        if (values[0] > 0) {
            // unlocked tokens
            super._transfer(address(this), recipient, values[0]);

            // Decrease allowance
            unchecked {
                _approve(sender, msg.sender, currentAllowance - values[0]);
            }
        }

        if (values[1] > 0) {
            // simple tokens
            super.transferFrom(sender, recipient, values[1]);
        }
        return true;
    }

    /**
     * @notice Balance of simple ERC20 tokens without any timelocks for a given address
     * @param who Address to calculate
     * @return amount The amount of simple ERC20 tokens available. See token.balanceOf
     **/
    function superBalanceOf(address who) public view returns (uint256) {
        return super.balanceOf(who);
    }

    /**
     * @notice Total unlocked balance for a given address - 1) balance of simple ERC20 tokens without any timelocks (superBalanceOf) + 2) unlocked tokens that remain (unlockedBalanceOf)
     * @param who Address to calculate
     * @return amount The unlocked total balance of
     **/
    function unlockedTotalBalanceOf(address who) public view returns (uint256) {
        return superBalanceOf(who) + unlockedBalanceOf(who);
    }

    /**
     * @notice Total locked balance for a given address across all timelocks
     * @param who Address to calculate
     * @return amount_
     */
    function lockedBalanceOf(
        address who
    ) public view returns (uint256 amount_) {
        uint256 _timelockCountOf = timelockCountOf(who);
        for (uint256 i; i < _timelockCountOf; ++i) {
            amount_ += lockedBalanceOfTimelock(who, i);
        }
    }

    /**
     * @notice Total unlocked balance remaining for a given address across all timelocks
     * @param who Address to calculate
     * @return amount_
     */
    function unlockedBalanceOf(
        address who
    ) public view returns (uint256 amount_) {
        uint256 _timelockCountOf = timelockCountOf(who);
        for (uint256 i; i < _timelockCountOf; ++i) {
            amount_ += unlockedBalanceOfTimelock(who, i);
        }
    }

    /**
     * @notice Total balance of tokens unlockedTotalBalanceOf + lockedBalanceOf
     * 1) balance of simple ERC20 tokens without any timelocks (superBalanceOf) + 2) unlocked tokens that remain (unlockedBalanceOf) + 3) locked tokens (lockedBalanceOf)
     * @param who Address to calculate
     * @return amount
     **/
    function balanceOf(address who) public view override returns (uint256) {
        return unlockedTotalBalanceOf(who) + lockedBalanceOf(who);
    }

    /**
    * @notice Cancel a cancelable timelock created by the fundReleaseSchedule function.
        WARNING: this function cannot cancel a release schedule created by fundReleaseSchedule
        If canceled the tokens that are locked at the time of the cancellation will be returned to the funder
        and unlocked tokens will be transferred to the recipient.
    * @param target The address that would receive the tokens when released from the timelock.
    * @param timelockIndex timelock index
    * @param scheduleId require it matches expected
    * @param commencementTimestamp require it matches expected
    * @param totalAmount require it matches expected
    * @param reclaimTokenTo reclaim token to
    * @return success Always returns true on completion so that a function calling it can revert if the required call did not succeed
    */
    function cancelTimelock(
        address target,
        uint256 timelockIndex,
        uint256 scheduleId,
        uint256 commencementTimestamp,
        uint256 totalAmount,
        address reclaimTokenTo
    ) external nonReentrant returns (bool success) {
        require(timelockCountOf(target) > timelockIndex, "Invalid timelock");
        require(reclaimTokenTo != address(0), "Invalid reclaimTokenTo");

        Timelock storage timelock = timelocks[target][timelockIndex];

        require(
            _canBeCanceled(timelock),
            "You are not allowed to cancel this timelock"
        );
        require(
            timelock.scheduleId == scheduleId,
            "Expected scheduleId does not match"
        );
        require(
            timelock.commencementTimestamp == commencementTimestamp,
            "Expected commencementTimestamp does not match"
        );
        require(
            timelock.totalAmount == totalAmount,
            "Expected totalAmount does not match"
        );

        uint256 canceledAmount = lockedBalanceOfTimelock(target, timelockIndex);

        require(canceledAmount > 0, "Timelock has no value left");

        enforceTransferRestrictions(
            timelock.funder,
            reclaimTokenTo,
            canceledAmount
        );

        uint256 paidAmount = unlockedBalanceOfTimelock(target, timelockIndex);

        IERC20(this).safeTransfer(reclaimTokenTo, canceledAmount);
        IERC20(this).safeTransfer(target, paidAmount);

        emit TimelockCanceled(
            msg.sender,
            target,
            timelockIndex,
            reclaimTokenTo,
            canceledAmount,
            paidAmount
        );

        timelock.tokensTransferred = timelock.totalAmount;
        return true;
    }

    /**
    * @notice transfers the unlocked token from an address's specific timelock
        It is typically more convenient to call transfer. But if the account has many timelocks the cost of gas
        for calling transfer may be too high. Calling transferTimelock from a specific timelock limits the transfer cost.
    * @param to the address that the tokens will be transferred to
    * @param value the number of token base units to me transferred to the to address
    * @param timelockId the specific timelock of the function caller to transfer unlocked tokens from
    * @return bool always true when completed
    */
    function transferTimelock(
        address to,
        uint256 value,
        uint256 timelockId
    ) external nonReentrant returns (bool) {
        require(
            unlockedBalanceOfTimelock(msg.sender, timelockId) >= value,
            "Amount > unlocked"
        );
        enforceTransferRestrictions(msg.sender, to, value);
        timelocks[msg.sender][timelockId].tokensTransferred += value;
        IERC20(this).safeTransfer(to, value);
        return true;
    }

    /**
    * @notice calculates how many tokens would be released at a specified time for a scheduleId.
        This is independent of any specific address or address's timelock.

    * @param commencedTimestamp the commencement time to use in the calculation for the scheduled
    * @param currentTimestamp the timestamp to calculate unlocked tokens for
    * @param amount the amount of tokens
    * @param scheduleId the schedule id used to calculate the unlocked amount
    * @return unlocked the total amount unlocked for the schedule given the other parameters
    */
    function calculateUnlocked(
        uint256 commencedTimestamp,
        uint256 currentTimestamp,
        uint256 amount,
        uint256 scheduleId
    ) public view returns (uint256 unlocked) {
        return
            calculateUnlocked(
                commencedTimestamp,
                currentTimestamp,
                amount,
                releaseSchedules[scheduleId]
            );
    }

    /**
     * @notice returns the total count of timelocks for a specific address
     * @param who the address to get the timelock count for
     * @return number of timelocks
     */
    function timelockCountOf(address who) public view returns (uint256) {
        return timelocks[who].length;
    }

    /**
    * @notice calculates how many tokens would be released at a specified time for a ReleaseSchedule struct.
            This is independent of any specific address or address's timelock.

    * @param commencedTimestamp the commencement time to use in the calculation for the scheduled
    * @param currentTimestamp the timestamp to calculate unlocked tokens for
    * @param amount the amount of tokens
    * @param releaseSchedule a ReleaseSchedule struct used to calculate the unlocked amount
    * @return unlocked the total amount unlocked for the schedule given the other parameters
    */
    function calculateUnlocked(
        uint256 commencedTimestamp,
        uint256 currentTimestamp,
        uint256 amount,
        ReleaseSchedule memory releaseSchedule
    ) public pure returns (uint256 unlocked) {
        return
            calculateUnlocked(
                commencedTimestamp,
                currentTimestamp,
                amount,
                releaseSchedule.releaseCount,
                releaseSchedule.delayUntilFirstReleaseInSeconds,
                releaseSchedule.initialReleasePortionInBips,
                releaseSchedule.periodBetweenReleasesInSeconds
            );
    }

    /**
     * @notice The same functionality as above function with spread format of `releaseSchedule` arg
     * @param commencedTimestamp the commencement time to use in the calculation for the scheduled
     * @param currentTimestamp the timestamp to calculate unlocked tokens for
     * @param amount the amount of tokens
     * @param releaseCount Total number of releases including any initial "cliff'
     * @param delayUntilFirstReleaseInSeconds "cliff" or 0 for immediate release
     * @param initialReleasePortionInBips Portion to release in 100ths of 1% (10000 BIPS per 100%)
     * @param periodBetweenReleasesInSeconds After the delay and initial release
     * @return unlocked the total amount unlocked for the schedule given the other parameters
     */
    function calculateUnlocked(
        uint256 commencedTimestamp,
        uint256 currentTimestamp,
        uint256 amount,
        uint256 releaseCount,
        uint256 delayUntilFirstReleaseInSeconds,
        uint256 initialReleasePortionInBips,
        uint256 periodBetweenReleasesInSeconds
    ) public pure returns (uint256 unlocked) {
        if (commencedTimestamp > currentTimestamp) {
            return 0;
        }
        uint256 secondsElapsed = currentTimestamp - commencedTimestamp;

        /// @notice return the full amount if the total lockup period has expired
        /// unlocked amounts in each period are truncated and round down remainders smaller than the smallest unit
        /// unlocking the full amount unlocks any remainder amounts in the final unlock period
        /// this is done first to reduce computation
        if (
            secondsElapsed >=
            delayUntilFirstReleaseInSeconds +
                (periodBetweenReleasesInSeconds * (releaseCount - 1))
        ) {
            return amount;
        }

        /// @notice unlock the initial release if the delay has elapsed
        if (secondsElapsed >= delayUntilFirstReleaseInSeconds) {
            unlocked = (amount * initialReleasePortionInBips) / BIPS_PRECISION;

            /// @notice if at least one period after the delay has passed
            if (
                secondsElapsed - delayUntilFirstReleaseInSeconds >=
                periodBetweenReleasesInSeconds
            ) {
                /// @notice calculate the number of additional periods that have passed (not including the initial release)
                /// this discards any remainders (ie it truncates / rounds down)
                uint256 additionalUnlockedPeriods = (secondsElapsed -
                    delayUntilFirstReleaseInSeconds) /
                    periodBetweenReleasesInSeconds;

                /// @notice calculate the amount of unlocked tokens for the additionalUnlockedPeriods
                /// multiplication is applied before division to delay truncating to the smallest unit
                /// this distributes unlocked tokens more evenly across unlock periods
                /// than truncated division followed by multiplication
                unlocked +=
                    ((amount - unlocked) * additionalUnlockedPeriods) /
                    (releaseCount - 1);
            }
        }

        return unlocked;
    }

    /**
     * @dev Freezes or unfreezes an address.
     * Tokens in a frozen address cannot be transferred from until the address is unfrozen.
     * @param addr The address to be frozen.
     * @param status The frozenAddress status of the address. True means frozen false means not frozen.
     */
    function freeze(
        address addr,
        bool status
    ) public validAddress(addr) onlyWalletsAdminOrTransferAdmin {
        _frozenAddresses[addr] = status;
        emit AddressFrozen(msg.sender, addr, status);
    }

    /**
     *  @notice Check if timelock can be cancelable by msg.sender
     */
    function _canBeCanceled(
        Timelock storage timelock
    ) private view returns (bool) {
        uint256 len = timelock.cancelableBy.length;
        for (uint256 i; i < len; ++i) {
            if (msg.sender == timelock.cancelableBy[i]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Get The locked balance for a specific address and specific timelock
     * @param who The address to check
     * @param timelockIndex Specific timelock belonging to the who address
     * @return locked Balance of the timelock
     * lockedBalanceOfTimelock
     */
    function lockedBalanceOfTimelock(
        address who,
        uint256 timelockIndex
    ) public view returns (uint256 locked) {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return
                timelock.totalAmount -
                totalUnlockedToDateOfTimelock(who, timelockIndex);
        }
    }

    /**
     * @notice Get the unlocked balance for a specific address and specific timelock
     * @param who the address to check
     * @param timelockIndex for a specific timelock belonging to the who address
     * @return unlocked balance of the timelock
     */
    function unlockedBalanceOfTimelock(
        address who,
        uint256 timelockIndex
    ) public view returns (uint256 unlocked) {
        Timelock memory timelock = timelockOf(who, timelockIndex);
        if (timelock.totalAmount <= timelock.tokensTransferred) {
            return 0;
        } else {
            return
                totalUnlockedToDateOfTimelock(who, timelockIndex) -
                timelock.tokensTransferred;
        }
    }

    /**
     * @notice Gets the total locked and unlocked balance of a specific address's timelocks
     * @param who The address to check
     * @param timelockIndex The index of the timelock for the who address
     * @return total Locked and unlocked amount for the specified timelock
     */
    function totalUnlockedToDateOfTimelock(
        address who,
        uint256 timelockIndex
    ) public view returns (uint256 total) {
        Timelock memory _timelock = timelockOf(who, timelockIndex);

        return
            calculateUnlocked(
                _timelock.commencementTimestamp,
                block.timestamp,
                _timelock.totalAmount,
                _timelock.scheduleId
            );
    }

    /**
     * @notice ERC20 standard interface function
     * Provide controls of Restricted and Lockup tokens
     * Can transfer simple ERC20 tokens and unlocked tokens at the same time
     * First will transfer unlocked tokens and then simple ERC20
     * @param recipient of transfer
     * @param amount of tokens to transfer
     * @return true On success / Reverted on error
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        enforceTransferRestrictions(msg.sender, recipient, amount);
        return _transfer(recipient, amount);
    }

    /**
     * @notice Get the struct details for an address's specific timelock
     * @param who Address to check
     * @param index The index of the timelock for the who address
     * @return timelock Struct with the attributes of the timelock
     */
    function timelockOf(
        address who,
        uint256 index
    ) public view returns (Timelock memory timelock) {
        return timelocks[who][index];
    }

    /**
     * @dev after transfer hook
     * @notice During a burn, this is invoked by the _burn function (ERC20.sol) which artificially sets `to` to the 0x0 address. Tokens are NOT actually transferred to 0x0 during a burn.
     * @param from from address
     * @param to address
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount); // Call parent hook

        /// @notice when to is 0x0, it's a burn (note - 0x0 is not actually transferred any tokens during burn)
        /// do NOT create a holder in that case
        if (!addressHasHolder(to) && to != address(0)) {
            // if holder does not exist
            _createHolderFromAddress(to);
        }

        /// @notice check that each resultant wallet balance meets requirements
        /// need to cover zero address case -> during mint/burn these conditions don't apply
        uint256 _minWalletBalance = minWalletBalance;

        if (_minWalletBalance > 0 && from != address(0)) {
            uint256 _balanceOfFrom = balanceOf(from);
            require(
                _balanceOfFrom == 0 || _balanceOfFrom >= minWalletBalance,
                "Invalid wallet balance"
            );
        }

        uint256 holderId_ = getHolderId(from);
        uint256 groupId_ = _transferGroups[from];

        /// @notice leave group if:
        /// 1) holderId (ie holder) is defined (they should be) &&
        /// 2) groupId > 0 (groupId == 0 has special properties that allow infinite users of 0 balance)
        /// 3) remaining holder group balance is 0
        bool _shouldLeaveGroup = holderId_ > 0 &&
            groupId_ > 0 &&
            holderBalanceByGroupId(holderId_, groupId_) == 0;
        if (_shouldLeaveGroup) {
            _leaveGroup(from);
        }
    }

    /**
     * @notice Check and calculate the availability to transfer tokens between accounts from simple and timelock balances
     * @param from Address from
     * @param value Amount of tokens
     * @return values Array of uint256[2] contains unlocked tokens at index 0, and simple ERC20 at index 1 that can be used for transfer
     */
    function validateTransfer(
        address from,
        uint256 value
    ) internal returns (uint256[2] memory values) {
        uint256 balance = superBalanceOf(from);
        uint256 unlockedBalance = unlockedBalanceOf(from);
        require(
            balance + unlockedBalance >= value,
            "Invalid: unlocked + balance < transfer amount"
        );

        uint256 remainingTransfer = value;

        /// @notice transfer from unlocked tokens
        for (uint256 i; i < timelockCountOf(from); ++i) {
            /// @notice if the timelock has no value left
            if (
                timelocks[from][i].tokensTransferred ==
                timelocks[from][i].totalAmount
            ) {
                continue;
            } else {
                uint256 _unlockedBalanceOfTimelock = unlockedBalanceOfTimelock(
                    from,
                    i
                );
                if (remainingTransfer > _unlockedBalanceOfTimelock) {
                    remainingTransfer -= _unlockedBalanceOfTimelock;
                    timelocks[from][i]
                        .tokensTransferred += _unlockedBalanceOfTimelock;
                } else {
                    timelocks[from][i].tokensTransferred += remainingTransfer;
                    remainingTransfer = 0;
                    break;
                }
            }
        }
        values[0] = value - remainingTransfer;
        /// @notice from unlockedValue
        values[1] = remainingTransfer;
        /// @notice from balanceOf
    }

    /**
     * @param to Address to
     * @param amount Amount of tokens
     * @param commencementTimestamp commencement timestamp
     * @param scheduleId schedule Id
     * @return timelock Id
     */
    function _fund(
        address to,
        uint256 amount,
        uint256 commencementTimestamp, // unix timestamp
        uint256 scheduleId,
        address funder
    ) internal returns (uint256) {
        require(timelocks[to].length < MAX_TIMELOCKS, "Max timelocks exceeded");
        require(amount >= minTimelockAmount, "Amount < min funding");
        require(to != address(0), "Cannot fund 0 address");
        require(scheduleId < releaseSchedules.length, "Bad scheduleId");
        require(
            amount >= releaseSchedules[scheduleId].releaseCount,
            "Amount must be >= releaseCount"
        );

        _transfer(address(this), amount);

        require(
            commencementTimestamp +
                releaseSchedules[scheduleId].delayUntilFirstReleaseInSeconds <=
                block.timestamp + maxReleaseDelay,
            "Initial release out of range"
        );

        Timelock memory timelock;
        timelock.scheduleId = scheduleId;
        timelock.commencementTimestamp = commencementTimestamp;
        timelock.totalAmount = amount;
        timelock.funder = funder;

        timelocks[to].push(timelock);
        return timelockCountOf(to) - 1;
    }

    /**
     * @param addr_ address to create Holder from
     * @return _holderId holder id
     */
    function _createHolderFromAddress(
        address addr_
    ) private validAddress(addr_) returns (uint256 _holderId) {
        require(!addressHasHolder(addr_), "Holder exists");

        require(holderCount < holderMax, "Reached maximum number of holders");
        ++holderCount;

        _holderIds.increment();
        _holderId = _holderIds.current();

        _holderIdByAddress[addr_] = _holderId;
        _holderAddressesByHolderId[_holderId].push(addr_);

        /// @notice explicitly define the groupId
        uint256 _groupId;

        /// @notice Auto join to 0 group
        ++holderGroupCount[_groupId];

        emit HolderCreated(_holderId, addr_);
    }

    /**
     * @dev Join into the group
     * @param addr_ address to join
     * @param groupId_ group Id to join
     * @param ignoreMinWalletBalance_ ignore minimum wallet balance on join
     */
    function _joinGroup(
        address addr_,
        uint256 groupId_,
        bool ignoreMinWalletBalance_
    ) private onlyExistingAddress(addr_) {
        int256 _groupMax = holderGroupMax[groupId_]; // max number holders allowed in new group
        bool _isHolderGroupMaxActive = _groupMax > 0; // only check group max if admin sets holderGroupMax[groupId_] > 0
        uint256 _holderId = _holderIdByAddress[addr_];
        uint256 _currentGroupId = _transferGroups[addr_];
        uint256 _currentGroupHolderBalance = holderBalanceByGroupId(
            _holderId,
            _currentGroupId
        );
        uint256 _newGroupHolderBalance = holderBalanceByGroupId(
            _holderId,
            groupId_
        );

        /// @notice condition flag only applies if minWalletBalance is set
        uint256 _minWalletBalance = minWalletBalance;
        if (!ignoreMinWalletBalance_ && _minWalletBalance > 0) {
            /// @notice if groupId is not 0 (special privileges in group0)
            /// @notice -> check whether to leave group
            if (groupId_ > 0) {
                uint256 _walletBalance = balanceOf(addr_);
                require(
                    _walletBalance >= _minWalletBalance,
                    "Balance is too low"
                );
            }
        }

        /// @notice if the new group's balance is initially 0, Holder is a new holder in that group
        if (_newGroupHolderBalance == 0) {
            /// @notice now we need to check if the group is at max capacity, but only if holderGroupMax is set > 0
            if (_isHolderGroupMaxActive) {
                require(
                    holderGroupCount[groupId_] < _groupMax,
                    "Reached maximum number of holders in group"
                );
            }
            ++holderGroupCount[groupId_];
        }

        /// @notice if current group's balance is equal to wallet addr balance, then remove from group
        /// it means they have no balance remaining
        if (_currentGroupHolderBalance == balanceOf(addr_)) {
            --holderGroupCount[_currentGroupId];
        }

        _transferGroups[addr_] = groupId_;
        emit AddressTransferGroup(msg.sender, addr_, groupId_);
    }

    /**
     * @param addr address to leave
     */
    function _leaveGroup(address addr) private {
        _joinGroup(addr, 0, true);
    }

    /**
     * @param recipient address to send to
     * @param amount amount to send
     */
    function _transfer(
        address recipient,
        uint256 amount
    ) private returns (bool) {
        uint256[2] memory values = validateTransfer(msg.sender, amount);
        if (values[0] > 0) {
            /// @notice unlocked tokens
            super._transfer(address(this), recipient, values[0]);
        }
        if (values[1] > 0) {
            /// @notice simple tokens
            super._transfer(msg.sender, recipient, values[1]);
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IDividends {
    /**
     * @title Functions
     */

    /// @dev Get unused ERC-20 tokens on snapshot
    /// @param token ERC-20 token address
    /// @param snapshotId Snapshot ID
    /// @return amount of ERC-20 tokens
    function tokensAt(
        address token,
        uint256 snapshotId
    ) external view returns (uint256);

    /**
     * @dev Fund any ERC-20 tokens into current contract
     * Tokens can be claimed by holders of RestrictedLockup Token uses claimDividends method
     * @param token ERC-20 token address
     * @param amount amount of tokens to fund
     * @param snapshotId snapshot ID of RestrictedLockup Token
     */
    function fundDividend(
        address token,
        uint256 amount,
        uint256 snapshotId
    ) external;

    /**
     * @dev Get balance of ERC-20 tokens funded at snapshot
     * @param token ERC-20 token address
     * @param snapshotId snapshot ID of RestrictedLockup Token
     * @return amount of ERC-20 tokens
     */
    function fundsAt(
        address token,
        uint256 snapshotId
    ) external view returns (uint256);

    /**
     * @dev Amount of ERC-20 tokens distributed to the holder of RestrictedLockup Token at snapshot
     * @param token ERC-20 token address
     * @param receiver RestrictedLockup Token's holder address
     * @param snapshotId snapshot ID of RestrictedLockup Token
     * @return amount of total ERC-20 tokens distributed to the receiver
     */
    function totalAwardedBalanceAt(
        address token,
        address receiver,
        uint256 snapshotId
    ) external view returns (uint256);

    /**
     * @dev Amount of ERC-20 tokens claimed by the holder of RestrictedLockup Token at snapshot
     * @param token ERC-20 token address
     * @param receiver RestrictedLockup Token's holder address
     * @param snapshotId snapshot ID of RestrictedLockup Token
     * @return amount of claimed ERC-20 tokens
     */
    function claimedBalanceAt(
        address token,
        address receiver,
        uint256 snapshotId
    ) external view returns (uint256);

    /**
     * @dev Amount of ERC-20 tokens that can be claimed by the holder of RestrictedLockup Token at snapshot
     * @param token ERC-20 token address
     * @param receiver RestrictedLockup Token's holder address
     * @param snapshotId snapshot ID of RestrictedLockup Token
     * @return amount of can be claimed ERC-20 tokens
     */
    function unclaimedBalanceAt(
        address token,
        address receiver,
        uint256 snapshotId
    ) external view returns (uint256);

    /**
     * @dev Claim ERC-20 tokens (dividends) by RestrictedLockup Tokens holder
     * Tokens can be claimed when its allowed by unclaimedBalanceAt
     * @param token ERC-20 token address
     * @param snapshotId snapshot ID of RestrictedLockup Token
     */
    function claimDividend(address token, uint256 snapshotId) external;

    /**
     * @dev Claim ERC-20 tokens (dividends) by RestrictedLockup Tokens holder, across multiple snapshotIds
     * Tokens can be claimed when its allowed by unclaimedBalanceAt
     * @param token ERC-20 token address
     * @param snapshotIds snapshot IDs of RestrictedLockup Token
     */
    function batchClaimDividend(
        address token,
        uint256[] calldata snapshotIds
    ) external;

    /**
     * @title Events
     */

    /// @notice This event is emitted when a snapshot is funded with ERC-20 tokens
    /// @param payer address of the payer
    /// @param token ERC-20 token address
    /// @param amount amount of ERC-20 tokens
    /// @param snapshotId snapshot ID of RestrictedLockup Token
    event Funded(
        address indexed payer,
        address indexed token,
        uint256 amount,
        uint256 indexed snapshotId
    );

    /// @notice This event is emitted when a holder of RestrictedLockup Token claims ERC-20 tokens
    /// @param payee address of the receiver
    /// @param token ERC-20 token address
    /// @param amount amount of ERC-20 tokens
    /// @param snapshotId snapshot ID of RestrictedLockup Token
    event Claimed(
        address indexed payee,
        address indexed token,
        uint256 amount,
        uint256 indexed snapshotId
    );
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

pragma solidity 0.8.17;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ITransferRules {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param token address of the token
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    function detectTransferRestriction(
        address token,
        address from,
        address to,
        uint256 value
    ) external view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    function messageForTransferRestriction(
        uint8 restrictionCode
    ) external view returns (string memory);

    function checkSuccess(uint8 restrictionCode) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC1404 is IERC20 {
    function detectTransferRestriction(
        address from,
        address to,
        uint256 value
    ) external view returns (uint8);

    function messageForTransferRestriction(
        uint8 restrictionCode
    ) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Arrays.sol";
import "../../../utils/Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minime/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./StorageSlot.sol";
import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using StorageSlot for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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