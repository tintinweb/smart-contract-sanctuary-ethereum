// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IWhitelist.sol";
import "./interfaces/IEmissionBooster.sol";
import "./libraries/ErrorCodes.sol";

contract Whitelist is IWhitelist, AccessControl, ReentrancyGuard {
    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);

    /// @notice EmissionBooster contract
    IEmissionBooster public immutable emissionBooster;

    /// @notice A maximum number of members. When membership reaches this number, no new members may
    /// join.
    uint256 public maxMembers;

    /// @notice The total number of members stored in the map.
    uint256 public memberCount;

    /// @notice Boolean variable. Protocol operation mode. In whitelist mode, only members
    /// from whitelist and who have NFT can work with protocol.
    bool public whitelistModeEnabled = true;

    // @notice Mapping of "accounts in the WhiteList"
    mapping(address => bool) public accountMembership;

    constructor(
        address _admin,
        IEmissionBooster emissionBooster_,
        uint256 _maxMembers,
        address[] memory memberList
    ) {
        require(memberList.length <= _maxMembers, ErrorCodes.MEMBERSHIP_LIMIT);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GATEKEEPER, _admin);
        emissionBooster = emissionBooster_;
        maxMembers = _maxMembers;

        uint256 savedMembers = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (accountMembership[memberList[i]]) {
                continue;
            }
            accountMembership[memberList[i]] = true;
            savedMembers++;
            emit MemberAdded(memberList[i]);
        }
        memberCount = savedMembers;
    }

    /// @inheritdoc IWhitelist
    function addMember(address newAccount) external onlyRole(GATEKEEPER) {
        require(!accountMembership[newAccount], ErrorCodes.MEMBER_ALREADY_ADDED);
        require(memberCount < maxMembers, ErrorCodes.MEMBERSHIP_LIMIT_REACHED);

        accountMembership[newAccount] = true;
        memberCount++;

        emit MemberAdded(newAccount);
    }

    /// @inheritdoc IWhitelist
    function removeMember(address accountToRemove) external onlyRole(GATEKEEPER) {
        require(accountMembership[accountToRemove], ErrorCodes.MEMBER_NOT_EXIST);

        delete accountMembership[accountToRemove];
        memberCount--;

        emit MemberRemoved(accountToRemove);
    }

    /// @inheritdoc IWhitelist
    function turnOffWhitelistMode() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        whitelistModeEnabled = false;
        emit WhitelistModeWasTurnedOff();
        emissionBooster.enableEmissionBoosting();
    }

    /// @inheritdoc IWhitelist
    function setMaxMembers(uint256 newThreshold) external onlyRole(GATEKEEPER) {
        require(newThreshold >= memberCount, ErrorCodes.MEMBERSHIP_LIMIT);
        maxMembers = newThreshold;
        emit MaxMemberAmountChanged(newThreshold);
    }

    /// @inheritdoc IWhitelist
    function isWhitelisted(address who) external view returns (bool) {
        return !whitelistModeEnabled || accountMembership[who] || emissionBooster.isAccountHaveTiers(who);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IWhitelist is IAccessControl {
    /**
     * @notice The given member was added to the whitelist
     */
    event MemberAdded(address);

    /**
     * @notice The given member was removed from the whitelist
     */
    event MemberRemoved(address);

    /**
     * @notice Protocol operation mode switched
     */
    event WhitelistModeWasTurnedOff();

    /**
     * @notice Amount of maxMembers changed
     */
    event MaxMemberAmountChanged(uint256);

    /**
     * @notice get maximum number of members.
     *      When membership reaches this number, no new members may join.
     */
    function maxMembers() external view returns (uint256);

    /**
     * @notice get the total number of members stored in the map.
     */
    function memberCount() external view returns (uint256);

    /**
     * @notice get protocol operation mode.
     */
    function whitelistModeEnabled() external view returns (bool);

    /**
     * @notice get is account member of whitelist
     */
    function accountMembership(address) external view returns (bool);

    /**
     * @notice get keccak-256 hash of GATEKEEPER role
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
     * @notice Add a new member to the whitelist.
     * @param newAccount The account that is being added to the whitelist.
     * @dev RESTRICTION: Gatekeeper only.
     */
    function addMember(address newAccount) external;

    /**
     * @notice Remove a member from the whitelist.
     * @param accountToRemove The account that is being removed from the whitelist.
     * @dev RESTRICTION: Gatekeeper only.
     */
    function removeMember(address accountToRemove) external;

    /**
     * @notice Disables whitelist mode and enables emission boost mode.
     * @dev RESTRICTION: Admin only.
     */
    function turnOffWhitelistMode() external;

    /**
     * @notice Set a new threshold of participants.
     * @param newThreshold New number of participants.
     * @dev RESTRICTION: Gatekeeper only.
     */
    function setMaxMembers(uint256 newThreshold) external;

    /**
     * @notice Check protocol operation mode. In whitelist mode, only members from whitelist and who have
     *         EmissionBooster can work with protocol.
     * @param who The address of the account to check for participation.
     */
    function isWhitelisted(address who) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

library ErrorCodes {
    // Common
    string internal constant ADMIN_ONLY = "E101";
    string internal constant UNAUTHORIZED = "E102";
    string internal constant OPERATION_PAUSED = "E103";
    string internal constant WHITELISTED_ONLY = "E104";
    string internal constant ADDRESS_IS_NOT_IN_AML_SYSTEM = "E105";
    string internal constant ADDRESS_IS_BLACKLISTED = "E106";

    // Invalid input
    string internal constant ADMIN_ADDRESS_CANNOT_BE_ZERO = "E201";
    string internal constant INVALID_REDEEM = "E202";
    string internal constant REDEEM_TOO_MUCH = "E203";
    string internal constant MARKET_NOT_LISTED = "E204";
    string internal constant INSUFFICIENT_LIQUIDITY = "E205";
    string internal constant INVALID_SENDER = "E206";
    string internal constant BORROW_CAP_REACHED = "E207";
    string internal constant BALANCE_OWED = "E208";
    string internal constant UNRELIABLE_LIQUIDATOR = "E209";
    string internal constant INVALID_DESTINATION = "E210";
    string internal constant INSUFFICIENT_STAKE = "E211";
    string internal constant INVALID_DURATION = "E212";
    string internal constant INVALID_PERIOD_RATE = "E213";
    string internal constant EB_TIER_LIMIT_REACHED = "E214";
    string internal constant INVALID_DEBT_REDEMPTION_RATE = "E215";
    string internal constant LQ_INVALID_SEIZE_DISTRIBUTION = "E216";
    string internal constant EB_TIER_DOES_NOT_EXIST = "E217";
    string internal constant EB_ZERO_TIER_CANNOT_BE_ENABLED = "E218";
    string internal constant EB_ALREADY_ACTIVATED_TIER = "E219";
    string internal constant EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT = "E220";
    string internal constant EB_CANNOT_MINT_TOKEN_FOR_ACTIVATED_TIER = "E221";
    string internal constant EB_EMISSION_BOOST_IS_NOT_IN_RANGE = "E222";
    string internal constant TARGET_ADDRESS_CANNOT_BE_ZERO = "E223";
    string internal constant INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT = "E224";
    string internal constant VESTING_SCHEDULE_ALREADY_EXISTS = "E225";
    string internal constant INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE = "E226";
    string internal constant NO_VESTING_SCHEDULE = "E227";
    string internal constant SCHEDULE_IS_IRREVOCABLE = "E228";
    string internal constant MNT_AMOUNT_IS_ZERO = "E230";
    string internal constant INCORRECT_AMOUNT = "E231";
    string internal constant MEMBERSHIP_LIMIT = "E232";
    string internal constant MEMBER_NOT_EXIST = "E233";
    string internal constant MEMBER_ALREADY_ADDED = "E234";
    string internal constant MEMBERSHIP_LIMIT_REACHED = "E235";
    string internal constant REPORTED_PRICE_SHOULD_BE_GREATER_THAN_ZERO = "E236";
    string internal constant MTOKEN_ADDRESS_CANNOT_BE_ZERO = "E237";
    string internal constant TOKEN_ADDRESS_CANNOT_BE_ZERO = "E238";
    string internal constant REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO = "E239";
    string internal constant FL_TOKEN_IS_NOT_UNDERLYING = "E240";
    string internal constant FL_AMOUNT_IS_TOO_LARGE = "E241";
    string internal constant FL_CALLBACK_FAILED = "E242";
    string internal constant DD_UNSUPPORTED_TOKEN = "E243";
    string internal constant DD_MARKET_ADDRESS_IS_ZERO = "E244";
    string internal constant DD_ROUTER_ADDRESS_IS_ZERO = "E245";
    string internal constant DD_RECEIVER_ADDRESS_IS_ZERO = "E246";
    string internal constant DD_BOT_ADDRESS_IS_ZERO = "E247";
    string internal constant DD_MARKET_NOT_FOUND = "E248";
    string internal constant DD_RECEIVER_NOT_FOUND = "E249";
    string internal constant DD_BOT_NOT_FOUND = "E250";
    string internal constant DD_ROUTER_ALREADY_SET = "E251";
    string internal constant DD_RECEIVER_ALREADY_SET = "E252";
    string internal constant DD_BOT_ALREADY_SET = "E253";
    string internal constant EB_MARKET_INDEX_IS_LESS_THAN_USER_INDEX = "E254";
    string internal constant LQ_INVALID_DRR_ARRAY = "E255";
    string internal constant LQ_INVALID_SEIZE_ARRAY = "E256";
    string internal constant LQ_INVALID_DEBT_REDEMPTION_RATE = "E257";
    string internal constant LQ_INVALID_SEIZE_INDEX = "E258";
    string internal constant LQ_DUPLICATE_SEIZE_INDEX = "E259";
    string internal constant DD_INVALID_TOKEN_IN_ADDRESS = "E260";
    string internal constant DD_INVALID_TOKEN_OUT_ADDRESS = "E261";
    string internal constant DD_INVALID_TOKEN_IN_AMOUNT = "E262";

    // Protocol errors
    string internal constant INVALID_PRICE = "E301";
    string internal constant MARKET_NOT_FRESH = "E302";
    string internal constant BORROW_RATE_TOO_HIGH = "E303";
    string internal constant INSUFFICIENT_TOKEN_CASH = "E304";
    string internal constant INSUFFICIENT_TOKENS_FOR_RELEASE = "E305";
    string internal constant INSUFFICIENT_MNT_FOR_GRANT = "E306";
    string internal constant TOKEN_TRANSFER_IN_UNDERFLOW = "E307";
    string internal constant NOT_PARTICIPATING_IN_BUYBACK = "E308";
    string internal constant NOT_ENOUGH_PARTICIPATING_ACCOUNTS = "E309";
    string internal constant NOTHING_TO_DISTRIBUTE = "E310";
    string internal constant ALREADY_PARTICIPATING_IN_BUYBACK = "E311";
    string internal constant MNT_APPROVE_FAILS = "E312";
    string internal constant TOO_EARLY_TO_DRIP = "E313";
    string internal constant BB_UNSTAKE_TOO_EARLY = "E314";
    string internal constant INSUFFICIENT_SHORTFALL = "E315";
    string internal constant HEALTHY_FACTOR_NOT_IN_RANGE = "E316";
    string internal constant BUYBACK_DRIPS_ALREADY_HAPPENED = "E317";
    string internal constant EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL = "E318";
    string internal constant NO_VESTING_SCHEDULES = "E319";
    string internal constant INSUFFICIENT_UNRELEASED_TOKENS = "E320";
    string internal constant ORACLE_PRICE_EXPIRED = "E321";
    string internal constant TOKEN_NOT_FOUND = "E322";
    string internal constant RECEIVED_PRICE_HAS_INVALID_ROUND = "E323";
    string internal constant FL_PULL_AMOUNT_IS_TOO_LOW = "E324";
    string internal constant INSUFFICIENT_TOTAL_PROTOCOL_INTEREST = "E325";
    string internal constant BB_ACCOUNT_RECENTLY_VOTED = "E326";
    string internal constant DD_SWAP_ROUTER_IS_ZERO = "E327";
    string internal constant DD_SWAP_CALL_FAILS = "E328";
    string internal constant LL_NEW_ROOT_CANNOT_BE_ZERO = "E329";

    // Invalid input - Admin functions
    string internal constant ZERO_EXCHANGE_RATE = "E401";
    string internal constant SECOND_INITIALIZATION = "E402";
    string internal constant MARKET_ALREADY_LISTED = "E403";
    string internal constant IDENTICAL_VALUE = "E404";
    string internal constant ZERO_ADDRESS = "E405";
    string internal constant EC_INVALID_PROVIDER_REPRESENTATIVE = "E406";
    string internal constant EC_PROVIDER_CANT_BE_REPRESENTATIVE = "E407";
    string internal constant OR_ORACLE_ADDRESS_CANNOT_BE_ZERO = "E408";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_SHOULD_BE_GREATER_THAN_ZERO = "E409";
    string internal constant OR_REPORTER_MULTIPLIER_SHOULD_BE_GREATER_THAN_ZERO = "E410";
    string internal constant INVALID_TOKEN = "E411";
    string internal constant INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA = "E412";
    string internal constant INVALID_REDUCE_AMOUNT = "E413";
    string internal constant LIQUIDATION_FEE_MANTISSA_SHOULD_BE_GREATER_THAN_ZERO = "E414";
    string internal constant INVALID_UTILISATION_FACTOR_MANTISSA = "E415";
    string internal constant INVALID_MTOKENS_OR_BORROW_CAPS = "E416";
    string internal constant FL_PARAM_IS_TOO_LARGE = "E417";
    string internal constant MNT_INVALID_NONVOTING_PERIOD = "E418";
    string internal constant INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL = "E419";
    string internal constant EC_INVALID_BOOSTS = "E420";
    string internal constant EC_ACCOUNT_IS_ALREADY_LIQUIDITY_PROVIDER = "E421";
    string internal constant EC_ACCOUNT_HAS_NO_AGREEMENT = "E422";
    string internal constant OR_TIMESTAMP_THRESHOLD_SHOULD_BE_GREATER_THAN_ZERO = "E423";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_TOO_BIG = "E424";
    string internal constant OR_REPORTER_MULTIPLIER_TOO_BIG = "E425";
    string internal constant SHOULD_HAVE_REVOCABLE_SCHEDULE = "E426";
    string internal constant MEMBER_NOT_IN_DELAY_LIST = "E427";
    string internal constant DELAY_LIST_LIMIT = "E428";
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./ISupervisor.sol";
import "./IRewardsHub.sol";
import "./IMToken.sol";
import "./ILinkageLeaf.sol";

interface IEmissionBooster is IAccessControl, ILinkageLeaf {
    /**
     * @notice Emitted when new Tier was created
     */
    event NewTierCreated(uint256 createdTier, uint32 endBoostBlock, uint256 emissionBoost);

    /**
     * @notice Emitted when Tier was enabled
     */
    event TierEnabled(
        IMToken market,
        uint256 enabledTier,
        uint32 startBoostBlock,
        uint224 mntSupplyIndex,
        uint224 mntBorrowIndex
    );

    /**
     * @notice Emitted when emission boost mode was enabled
     */
    event EmissionBoostEnabled(address caller);

    /**
     * @notice Emitted when MNT supply index of the tier ending on the market was saved to storage
     */
    event SupplyIndexUpdated(address market, uint256 nextTier, uint224 newIndex, uint32 endBlock);

    /**
     * @notice Emitted when MNT borrow index of the tier ending on the market was saved to storage
     */
    event BorrowIndexUpdated(address market, uint256 nextTier, uint224 newIndex, uint32 endBlock);

    /**
     * @notice get the Tier for each MinterestNFT token
     */
    function tokenTier(uint256) external view returns (uint256);

    /**
     * @notice get a list of all created Tiers
     */
    function tiers(uint256)
        external
        view
        returns (
            uint32,
            uint32,
            uint256
        );

    /**
     * @notice get status of emission boost mode.
     */
    function isEmissionBoostingEnabled() external view returns (bool);

    /**
     * @notice get Stored markets indexes per block.
     */
    function marketSupplyIndexes(IMToken, uint256) external view returns (uint256);

    /**
     * @notice get Stored markets indexes per block.
     */
    function marketBorrowIndexes(IMToken, uint256) external view returns (uint256);

    /**
     * @notice Mint token hook which is called from MinterestNFT.mint() and sets specific
     *      settings for this NFT
     * @param to_ NFT ovner
     * @param ids_ NFTs IDs
     * @param amounts_ Amounts of minted NFTs per tier
     * @param tiers_ NFT tiers
     * @dev RESTRICTION: MinterestNFT only
     */
    function onMintToken(
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        uint256[] memory tiers_
    ) external;

    /**
     * @notice Transfer token hook which is called from MinterestNFT.transfer() and sets specific
     *      settings for this NFT
     * @param from_ Address of the tokens previous owner. Should not be zero (minter).
     * @param to_ Address of the tokens new owner.
     * @param ids_ NFTs IDs
     * @param amounts_ Amounts of minted NFTs per tier
     * @dev RESTRICTION: MinterestNFT only
     */
    function onTransferToken(
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    ) external;

    /**
     * @notice Enables emission boost mode.
     * @dev Admin function for enabling emission boosts.
     * @dev RESTRICTION: Whitelist only
     */
    function enableEmissionBoosting() external;

    /**
     * @notice Creates new Tiers for MinterestNFT tokens
     * @dev Admin function for creating Tiers
     * @param endBoostBlocks Emission boost end blocks for created Tiers
     * @param emissionBoosts Emission boosts for created Tiers, scaled by 1e18
     * Note: The arrays passed to the function must be of the same length and the order of the elements must match
     *      each other
     * @dev RESTRICTION: Admin only
     */
    function createTiers(uint32[] memory endBoostBlocks, uint256[] memory emissionBoosts) external;

    /**
     * @notice Enables emission boost in specified Tiers
     * @param tiersForEnabling Tier for enabling emission boost
     * @dev RESTRICTION: Admin only
     */
    function enableTiers(uint256[] memory tiersForEnabling) external;

    /**
     * @notice Return the number of created Tiers
     * @return The number of created Tiers
     */
    function getNumberOfTiers() external view returns (uint256);

    /**
     * @notice Checks if the specified Tier is active
     * @param tier_ The Tier that is being checked
     */
    function isTierActive(uint256 tier_) external view returns (bool);

    /**
     * @notice Checks if the specified Tier exists
     * @param tier_ The Tier that is being checked
     */
    function tierExists(uint256 tier_) external view returns (bool);

    /**
     * @param account_ The address of the account
     * @return Bitmap of all accounts tiers
     */
    function getAccountTiersBitmap(address account_) external view returns (uint256);

    /**
     * @param account_ The address of the account to check if they have any tokens with tier
     */
    function isAccountHaveTiers(address account_) external view returns (bool);

    /**
     * @param account_ Address of the account
     * @return tier Highest tier number
     * @return boost Highest boost amount
     */
    function getCurrentAccountBoost(address account_) external view returns (uint256 tier, uint256 boost);

    /**
     * @notice Calculates emission boost for the account.
     * @param market_ Market for which we are calculating emission boost
     * @param account_ The address of the account for which we are calculating emission boost
     * @param userLastIndex_ The account's last updated mntBorrowIndex or mntSupplyIndex
     * @param userLastBlock_ The block number in which the index for the account was last updated
     * @param marketIndex_ The market's current mntBorrowIndex or mntSupplyIndex
     * @param isSupply_ boolean value, if true, then return calculate emission boost for suppliers
     * @return boostedIndex Boost part of delta index
     */
    function calculateEmissionBoost(
        IMToken market_,
        address account_,
        uint256 userLastIndex_,
        uint256 userLastBlock_,
        uint256 marketIndex_,
        bool isSupply_
    ) external view returns (uint256 boostedIndex);

    /**
     * @notice Update MNT supply index for market for NFT tiers that are expired but not yet updated.
     * @dev This function checks if there are tiers to update and process them one by one:
     *      calculates the MNT supply index depending on the delta index and delta blocks between
     *      last MNT supply index update and the current state,
     *      emits SupplyIndexUpdated event and recalculates next tier to update.
     * @param market Address of the market to update
     * @param lastUpdatedBlock Last updated block number
     * @param lastUpdatedIndex Last updated index value
     * @param currentSupplyIndex Current MNT supply index value
     * @dev RESTRICTION: RewardsHub only
     */
    function updateSupplyIndexesHistory(
        IMToken market,
        uint256 lastUpdatedBlock,
        uint256 lastUpdatedIndex,
        uint256 currentSupplyIndex
    ) external;

    /**
     * @notice Update MNT borrow index for market for NFT tiers that are expired but not yet updated.
     * @dev This function checks if there are tiers to update and process them one by one:
     *      calculates the MNT borrow index depending on the delta index and delta blocks between
     *      last MNT borrow index update and the current state,
     *      emits BorrowIndexUpdated event and recalculates next tier to update.
     * @param market Address of the market to update
     * @param lastUpdatedBlock Last updated block number
     * @param lastUpdatedIndex Last updated index value
     * @param currentBorrowIndex Current MNT borrow index value
     * @dev RESTRICTION: RewardsHub only
     */
    function updateBorrowIndexesHistory(
        IMToken market,
        uint256 lastUpdatedBlock,
        uint256 lastUpdatedIndex,
        uint256 currentBorrowIndex
    ) external;

    /**
     * @notice Get Id of NFT tier to update next on provided market MNT index, supply or borrow
     * @param market Market for which should the next Tier to update be updated
     * @param isSupply_ Flag that indicates whether MNT supply or borrow market should be updated
     * @return Id of tier to update
     */
    function getNextTierToBeUpdatedIndex(IMToken market, bool isSupply_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IMToken.sol";
import "./IBuyback.sol";
import "./IRewardsHub.sol";
import "./ILinkageLeaf.sol";
import "./IWhitelist.sol";

/**
 * @title Minterest Supervisor Contract
 * @author Minterest
 */
interface ISupervisor is IAccessControl, ILinkageLeaf {
    /**
     * @notice Emitted when an admin supports a market
     */
    event MarketListed(IMToken mToken);

    /**
     * @notice Emitted when an account enable a market
     */
    event MarketEnabledAsCollateral(IMToken mToken, address account);

    /**
     * @notice Emitted when an account disable a market
     */
    event MarketDisabledAsCollateral(IMToken mToken, address account);

    /**
     * @notice Emitted when a utilisation factor is changed by admin
     */
    event NewUtilisationFactor(
        IMToken mToken,
        uint256 oldUtilisationFactorMantissa,
        uint256 newUtilisationFactorMantissa
    );

    /**
     * @notice Emitted when liquidation fee is changed by admin
     */
    event NewLiquidationFee(IMToken marketAddress, uint256 oldLiquidationFee, uint256 newLiquidationFee);

    /**
     * @notice Emitted when borrow cap for a mToken is changed
     */
    event NewBorrowCap(IMToken indexed mToken, uint256 newBorrowCap);

    /**
     * @notice Per-account mapping of "assets you are in"
     */
    function accountAssets(address, uint256) external view returns (IMToken);

    /**
     * @notice Collection of states of supported markets
     * @dev Types containing (nested) mappings could not be parameters or return of external methods
     */
    function markets(IMToken)
        external
        view
        returns (
            bool isListed,
            uint256 utilisationFactorMantissa,
            uint256 liquidationFeeMantissa
        );

    /**
     * @notice get A list of all markets
     */
    function allMarkets(uint256) external view returns (IMToken);

    /**
     * @notice get Borrow caps enforced by beforeBorrow for each mToken address.
     */
    function borrowCaps(IMToken) external view returns (uint256);

    /**
     * @notice get keccak-256 hash of gatekeeper role
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of timelock
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice Returns the assets an account has enabled as collateral
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has enabled as collateral
     */
    function getAccountAssets(address account) external view returns (IMToken[] memory);

    /**
     * @notice Returns whether the given account is enabled as collateral in the given asset
     * @param account The address of the account to check
     * @param mToken The mToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, IMToken mToken) external view returns (bool);

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param mTokens The list of addresses of the mToken markets to be enabled as collateral
     */
    function enableAsCollateral(IMToken[] memory mTokens) external;

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param mTokenAddress The address of the asset to be removed
     */
    function disableAsCollateral(IMToken mTokenAddress) external;

    /**
     * @notice Makes checks if the account should be allowed to lend tokens in the given market
     * @param mToken The market to verify the lend against
     * @param lender The account which would get the lent tokens
     */
    function beforeLend(IMToken mToken, address lender) external;

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market and triggers emission system
     * @param mToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of mTokens to exchange for the underlying asset in the market
     * @param isAmlProcess Do we need to check the AML system or not
     */
    function beforeRedeem(
        IMToken mToken,
        address redeemer,
        uint256 redeemTokens,
        bool isAmlProcess
    ) external;

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param mToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     */
    function beforeBorrow(
        IMToken mToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param mToken The market to verify the repay against
     * @param borrower The account which would borrowed the asset
     */
    function beforeRepayBorrow(IMToken mToken, address borrower) external;

    /**
     * @notice Checks if the seizing of assets should be allowed to occur (auto liquidation process)
     * @param mToken Asset which was used as collateral and will be seized
     * @param liquidator_ The address of liquidator contract
     * @param borrower The address of the borrower
     */
    function beforeAutoLiquidationSeize(
        IMToken mToken,
        address liquidator_,
        address borrower
    ) external;

    /**
     * @notice Checks if the sender should be allowed to repay borrow in the given market (auto liquidation process)
     * @param liquidator_ The address of liquidator contract
     * @param borrower_ The account which borrowed the asset
     * @param mToken_ The market to verify the repay against
     */
    function beforeAutoLiquidationRepay(
        address liquidator_,
        address borrower_,
        IMToken mToken_
    ) external;

    /**
     * @notice Checks if the address is the Liquidation contract
     * @dev Used in liquidation process
     * @param liquidator_ Prospective address of the Liquidation contract
     */
    function isLiquidator(address liquidator_) external view;

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param mToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of mTokens to transfer
     */
    function beforeTransfer(
        IMToken mToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /**
     * @notice Makes checks before flash loan in MToken
     * @param mToken The address of the token
     * receiver - The address of the loan receiver
     * amount - How much tokens to flash loan
     * fee - Flash loan fee
     */
    function beforeFlashLoan(
        IMToken mToken,
        address, /* receiver */
        uint256, /* amount */
        uint256 /* fee */
    ) external view;

    /**
     * @notice Calculate account liquidity in USD related to utilisation factors of underlying assets
     * @return (USD value above total utilisation requirements of all assets,
     *           USD value below total utilisation requirements of all assets)
     */
    function getAccountLiquidity(address account) external view returns (uint256, uint256);

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param mTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        IMToken mTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) external returns (uint256, uint256);

    /**
     * @notice Get liquidationFeeMantissa and utilisationFactorMantissa for market
     * @param market Market for which values are obtained
     * @return (liquidationFeeMantissa, utilisationFactorMantissa)
     */
    function getMarketData(IMToken market) external view returns (uint256, uint256);

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(uint256 redeemAmount, uint256 redeemTokens) external view;

    /**
     * @notice Sets the utilisationFactor for a market
     * @dev Governance function to set per-market utilisationFactor
     * @param mToken The market to set the factor on
     * @param newUtilisationFactorMantissa The new utilisation factor, scaled by 1e18
     * @dev RESTRICTION: Timelock only.
     */
    function setUtilisationFactor(IMToken mToken, uint256 newUtilisationFactorMantissa) external;

    /**
     * @notice Sets the liquidationFee for a market
     * @dev Governance function to set per-market liquidationFee
     * @param mToken The market to set the fee on
     * @param newLiquidationFeeMantissa The new liquidation fee, scaled by 1e18
     * @dev RESTRICTION: Timelock only.
     */
    function setLiquidationFee(IMToken mToken, uint256 newLiquidationFeeMantissa) external;

    /**
     * @notice Add the market to the markets mapping and set it as listed, also initialize MNT market state.
     * @dev Admin function to set isListed and add support for the market
     * @param mToken The address of the market (token) to list
     * @dev RESTRICTION: Admin only.
     */
    function supportMarket(IMToken mToken) external;

    /**
     * @notice Set the given borrow caps for the given mToken markets.
     *         Borrowing that brings total borrows to or above borrow cap will revert.
     * @dev Admin or gateKeeper function to set the borrow caps.
     *      A borrow cap of 0 corresponds to unlimited borrowing.
     * @param mTokens The addresses of the markets (tokens) to change the borrow caps for
     * @param newBorrowCaps The new borrow cap values in underlying to be set.
     *                      A value of 0 corresponds to unlimited borrowing.
     * @dev RESTRICTION: Gatekeeper only.
     */
    function setMarketBorrowCaps(IMToken[] calldata mTokens, uint256[] calldata newBorrowCaps) external;

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() external view returns (IMToken[] memory);

    /**
     * @notice Returns true if market is listed in Supervisor
     */
    function isMarketListed(IMToken) external view returns (bool);

    /**
     * @notice Check that account is not in the black list and protocol operations are available.
     * @param account The address of the account to check
     */
    function isNotBlacklisted(address account) external view returns (bool);

    /**
     * @notice Check if transfer of MNT is allowed for accounts.
     * @param from The source account address to check
     * @param to The destination account address to check
     */
    function isMntTransferAllowed(address from, address to) external view returns (bool);

    /**
     * @notice Returns block number
     */
    function getBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./IMToken.sol";
import "./ILinkageLeaf.sol";

interface IRewardsHub is ILinkageLeaf {
    event DistributedSupplierMnt(
        IMToken indexed mToken,
        address indexed supplier,
        uint256 mntDelta,
        uint256 mntSupplyIndex
    );
    event DistributedBorrowerMnt(
        IMToken indexed mToken,
        address indexed borrower,
        uint256 mntDelta,
        uint256 mntBorrowIndex
    );
    event EmissionRewardAccrued(address indexed account, uint256 regularAmount, uint256 delayedAmount);
    event RepresentativeRewardAccrued(
        address indexed account,
        address provider,
        uint256 regularAmount,
        uint256 delayedAmount
    );
    event BuybackRewardAccrued(address indexed account, uint256 regularAmount, uint256 delayedAmount);
    event Withdraw(address indexed account, uint256 amount);
    event MntGranted(address recipient, uint256 amount);

    event MntSupplyEmissionRateUpdated(IMToken indexed mToken, uint256 newSupplyEmissionRate);
    event MntBorrowEmissionRateUpdated(IMToken indexed mToken, uint256 newBorrowEmissionRate);

    struct DelayEntry {
        uint256 delayed;
        uint224 claimRate;
        uint32 lastClaim;
    }

    /**
     * @notice get keccak-256 hash of gatekeeper
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of timelock
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     *   @dev Gets amounts of regular rewards for individual accounts.
     */
    function balances(address account) external view returns (uint256);

    /**
     * @notice Gets the rate at which MNT is distributed to the corresponding supply market (per block)
     */
    function mntSupplyEmissionRate(IMToken) external view returns (uint256);

    /**
     * @notice Gets the rate at which MNT is distributed to the corresponding borrow market (per block)
     */
    function mntBorrowEmissionRate(IMToken) external view returns (uint256);

    /**
     * @notice Gets the MNT market supply state for each market
     */
    function mntSupplyState(IMToken) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets the MNT market borrow state for each market
     */
    function mntBorrowState(IMToken) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets the MNT supply index and block number for each market
     */
    function mntSupplierState(IMToken, address) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets the MNT borrow index and block number for each market
     */
    function mntBorrowerState(IMToken, address) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets summary amount of available and delayed balances of an account.
     */
    function totalBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Gets amount of MNT that can be withdrawn from an account at this block.
     */
    function availableBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Gets amount of delayed MNT of an account.
     */
    function delayedBalanceOf(address account) external view returns (DelayEntry memory);

    /**
     * @notice Gets delay period start, claim period start and claim period end timestamps.
     */
    function delayParameters()
        external
        view
        returns (
            uint32 delayStart,
            uint32 claimStart,
            uint32 claimEnd
        );

    /**
     * @notice Initializes market in RewardsHub. Should be called once from Supervisor.supportMarket
     * @dev RESTRICTION: Supervisor only
     */
    function initMarket(IMToken mToken) external;

    /**
     * @notice Accrues MNT to the market by updating the borrow and supply indexes
     * @dev This method doesn't update MNT index history in Minterest NFT.
     * @param market The market whose supply and borrow index to update
     * @return (MNT supply index, MNT borrow index)
     */
    function updateAndGetMntIndexes(IMToken market) external returns (uint224, uint224);

    /**
     * @notice Shorthand function to distribute MNT emissions from supplies of one market.
     */
    function distributeSupplierMnt(IMToken mToken, address account) external;

    /**
     * @notice Shorthand function to distribute MNT emissions from borrows of one market.
     */
    function distributeBorrowerMnt(IMToken mToken, address account) external;

    /**
     * @notice Updates market indices and distributes tokens (if any) for holder
     * @dev Updates indices and distributes only for those markets where the holder have a
     * non-zero supply or borrow balance.
     * @param account The address to distribute MNT for
     */
    function distributeAllMnt(address account) external;

    /**
     * @notice Distribute all MNT accrued by the accounts
     * @param accounts The addresses to distribute MNT for
     * @param mTokens The list of markets to distribute MNT in
     * @param borrowers Whether or not to distribute MNT earned by borrowing
     * @param suppliers Whether or not to distribute MNT earned by supplying
     */
    function distributeMnt(
        address[] memory accounts,
        IMToken[] memory mTokens,
        bool borrowers,
        bool suppliers
    ) external;

    /**
     * @notice Accrues buyback reward
     * @dev RESTRICTION: Buyback only
     */
    function accrueBuybackReward(
        address account,
        uint256 buybackIndex,
        uint256 accountIndex,
        uint256 accountWeight
    ) external;

    /**
     * @notice Gets part of delayed rewards that have become available.
     */
    function getClaimableDelayed(address account) external view returns (uint256);

    /**
     * @notice Transfers available part of MNT rewards to the sender.
     * This will decrease accounts buyback and voting weights.
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Transfers
     * @dev RESTRICTION: Admin only
     */
    function grant(address recipient, uint256 amount) external;

    /**
     * @notice Set MNT borrow and supply emission rates for a single market
     * @param mToken The market whose MNT emission rate to update
     * @param newMntSupplyEmissionRate New supply MNT emission rate for market
     * @param newMntBorrowEmissionRate New borrow MNT emission rate for market
     * @dev RESTRICTION Timelock only
     */
    function setMntEmissionRates(
        IMToken mToken,
        uint256 newMntSupplyEmissionRate,
        uint256 newMntBorrowEmissionRate
    ) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ILinkageRoot.sol";

interface ILinkageLeaf {
    /**
     * @notice Emitted when root contract address is changed
     */
    event LinkageRootSwitched(ILinkageRoot newRoot, ILinkageRoot oldRoot);

    /**
     * @notice Connects new root contract address
     * @param newRoot New root contract address
     */
    function switchLinkageRoot(ILinkageRoot newRoot) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IInterestRateModel.sol";

interface IMToken is IAccessControl, IERC20, IERC3156FlashLender, IERC165 {
    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalProtocolInterest
    );

    /**
     * @notice Event emitted when tokens are lended
     */
    event Lend(address lender, uint256 lendAmount, uint256 lendTokens, uint256 newTotalTokenSupply);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens, uint256 newTotalTokenSupply);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are seized
     */
    event Seize(
        address borrower,
        address receiver,
        uint256 seizeTokens,
        uint256 accountsTokens,
        uint256 totalSupply,
        uint256 seizeUnderlyingAmount
    );

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is repaid during autoliquidation
     */
    event AutoLiquidationRepayBorrow(
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrowsNew,
        uint256 totalBorrowsNew,
        uint256 TotalProtocolInterestNew
    );

    /**
     * @notice Event emitted when flash loan is executed
     */
    event FlashLoanExecuted(address receiver, uint256 amount, uint256 fee);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(IInterestRateModel oldInterestRateModel, IInterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the protocol interest factor is changed
     */
    event NewProtocolInterestFactor(
        uint256 oldProtocolInterestFactorMantissa,
        uint256 newProtocolInterestFactorMantissa
    );

    /**
     * @notice Event emitted when the flash loan max share is changed
     */
    event NewFlashLoanMaxShare(uint256 oldMaxShare, uint256 newMaxShare);

    /**
     * @notice Event emitted when the flash loan fee is changed
     */
    event NewFlashLoanFee(uint256 oldFee, uint256 newFee);

    /**
     * @notice Event emitted when the protocol interest are added
     */
    event ProtocolInterestAdded(address benefactor, uint256 addAmount, uint256 newTotalProtocolInterest);

    /**
     * @notice Event emitted when the protocol interest reduced
     */
    event ProtocolInterestReduced(address admin, uint256 reduceAmount, uint256 newTotalProtocolInterest);

    /**
     * @notice Value is the Keccak-256 hash of "TIMELOCK"
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice Underlying asset for this MToken
     */
    function underlying() external view returns (IERC20);

    /**
     * @notice EIP-20 token name for this token
     */
    function name() external view returns (string memory);

    /**
     * @notice EIP-20 token symbol for this token
     */
    function symbol() external view returns (string memory);

    /**
     * @notice EIP-20 token decimals for this token
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Model which tells what the current interest rate should be
     */
    function interestRateModel() external view returns (IInterestRateModel);

    /**
     * @notice Initial exchange rate used when lending the first MTokens (used when totalTokenSupply = 0)
     */
    function initialExchangeRateMantissa() external view returns (uint256);

    /**
     * @notice Fraction of interest currently set aside for protocol interest
     */
    function protocolInterestFactorMantissa() external view returns (uint256);

    /**
     * @notice Block number that interest was last accrued at
     */
    function accrualBlockNumber() external view returns (uint256);

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    function borrowIndex() external view returns (uint256);

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    function totalBorrows() external view returns (uint256);

    /**
     * @notice Total amount of protocol interest of the underlying held in this market
     */
    function totalProtocolInterest() external view returns (uint256);

    /**
     * @notice Share of market's current underlying token balance that can be used as flash loan (scaled by 1e18).
     */
    function maxFlashLoanShare() external view returns (uint256);

    /**
     * @notice Share of flash loan amount that would be taken as fee (scaled by 1e18).
     */
    function flashLoanFeeShare() external view returns (uint256);

    /**
     * @notice Returns total token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by supervisor to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Returns the current per-block borrow interest rate for this mToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this mToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external returns (uint256);

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's
     *         borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external returns (uint256);

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Get cash balance of this mToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint256);

    /**
     * @notice Applies accrued interest to total borrows and protocol interest
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() external;

    /**
     * @notice Sender supplies assets into the market and receives mTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param lendAmount The amount of the underlying asset to supply
     */
    function lend(uint256 lendAmount) external;

    /**
     * @notice Sender redeems mTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of mTokens to redeem into underlying
     */
    function redeem(uint256 redeemTokens) external;

    /**
     * @notice Redeems all mTokens for account in exchange for the underlying asset.
     * Can only be called within the AML system!
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param account An account that is potentially sanctioned by the AML system
     */
    function redeemByAmlDecision(address account) external;

    /**
     * @notice Sender redeems mTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming mTokens
     */
    function redeemUnderlying(uint256 redeemAmount) external;

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     */
    function borrow(uint256 borrowAmount) external;

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     */
    function repayBorrow(uint256 repayAmount) external;

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external;

    /**
     * @notice Liquidator repays a borrow belonging to borrower
     * @param borrower_ the account with the debt being payed off
     * @param repayAmount_ the amount of underlying tokens being returned
     */
    function autoLiquidationRepayBorrow(address borrower_, uint256 repayAmount_) external;

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract.
     *         Tokens are sent to admin (timelock)
     * @param token The address of the ERC-20 token to sweep
     * @dev RESTRICTION: Admin only.
     */
    function sweepToken(IERC20 token, address admin_) external;

    /**
     * @notice Burns collateral tokens at the borrower's address, transfer underlying assets
     to the DeadDrop or Liquidator address.
     * @dev Called only during an auto liquidation process, msg.sender must be the Liquidation contract.
     * @param borrower_ The account having collateral seized
     * @param seizeUnderlyingAmount_ The number of underlying assets to seize. The caller must ensure
     that the parameter is greater than zero.
     * @param isLoanInsignificant_ Marker for insignificant loan whose collateral must be credited to the
     protocolInterest
     * @param receiver_ Address that receives accounts collateral
     */
    function autoLiquidationSeize(
        address borrower_,
        uint256 seizeUnderlyingAmount_,
        bool isLoanInsignificant_,
        address receiver_
    ) external;

    /**
     * @notice The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @notice The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @notice Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @notice accrues interest and sets a new protocol interest factor for the protocol
     * @dev Admin function to accrue interest and set a new protocol interest factor
     * @dev RESTRICTION: Timelock only.
     */
    function setProtocolInterestFactor(uint256 newProtocolInterestFactorMantissa) external;

    /**
     * @notice Accrues interest and increase protocol interest by transferring from msg.sender
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterest(uint256 addAmount_) external;

    /**
     * @notice Can only be called by liquidation contract. Increase protocol interest by transferring from payer.
     * @dev Calling code should make sure that accrueInterest() was called before.
     * @param payer_ The address from which the protocol interest will be transferred
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterestBehalf(address payer_, uint256 addAmount_) external;

    /**
     * @notice Accrues interest and reduces protocol interest by transferring to admin
     * @param reduceAmount Amount of reduction to protocol interest
     * @dev RESTRICTION: Admin only.
     */
    function reduceProtocolInterest(uint256 reduceAmount, address admin_) external;

    /**
     * @notice accrues interest and updates the interest rate model using setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @dev RESTRICTION: Admin only.
     */
    function setInterestRateModel(IInterestRateModel newInterestRateModel) external;

    /**
     * @notice Updates share of markets cash that can be used as maximum amount of flash loan.
     * @param newMax New max amount share
     * @dev RESTRICTION: Admin only.
     */
    function setFlashLoanMaxShare(uint256 newMax) external;

    /**
     * @notice Updates fee of flash loan.
     * @param newFee New fee share of flash loan
     * @dev RESTRICTION: Timelock only.
     */
    function setFlashLoanFeeShare(uint256 newFee) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./ILinkageLeaf.sol";

interface IBuyback is IAccessControl, ILinkageLeaf {
    event Stake(address who, uint256 amount, uint256 discounted);
    event Unstake(address who, uint256 amount);
    event NewBuyback(uint256 amount, uint256 share);
    event ParticipateBuyback(address who);
    event LeaveBuyback(address who, uint256 currentStaked);
    event BuybackWeightChanged(address who, uint256 newWeight, uint256 oldWeight, uint256 newTotalWeight);

    /**
     * @notice Gets parameters used to calculate the discount curve.
     * @return start The timestamp from which the discount starts
     * @return flatSeconds Seconds from protocol start when approximation function has minimum value
     * ~ 4.44 years of the perfect year, at this point df/dx == 0
     * @return flatRate Flat rate of the discounted MNTs after the kink point.
     * Equal to the percentage at flatSeconds time
     */
    function discountParameters()
        external
        view
        returns (
            uint256 start,
            uint256 flatSeconds,
            uint256 flatRate
        );

    /**
     * @notice Applies current discount rate to the supplied amount
     * @param amount The amount to discount
     * @return Discounted amount in range [0; amount]
     */
    function discountAmount(uint256 amount) external view returns (uint256);

    /**
     * @notice Calculates value of polynomial approximation of e^-kt, k = 0.725, t in seconds of a perfect year
     * function follows e^(-0.725*t) ~ 1 - 0.7120242*x + 0.2339357*x^2 - 0.04053335*x^3 + 0.00294642*x^4
     * up to the minimum and then continues with a flat rate
     * @param secondsElapsed Seconds elapsed from the start block
     * @return Discount rate in range [0..1] with precision mantissa 1e18
     */
    function getPolynomialFactor(uint256 secondsElapsed) external pure returns (uint256);

    /**
     * @notice Gets all info about account membership in Buyback
     */
    function getMemberInfo(address account)
        external
        view
        returns (
            bool participating,
            uint256 weight,
            uint256 lastIndex,
            uint256 rawStake,
            uint256 discountedStake
        );

    /**
     * @notice Gets if an account is participating in Buyback
     */
    function isParticipating(address account) external view returns (bool);

    /**
     * @notice Gets discounted stake of the account
     */
    function getDiscountedStake(address account) external view returns (uint256);

    /**
     * @notice Gets buyback weight of an account
     */
    function getWeight(address account) external view returns (uint256);

    /**
     * @notice Gets total Buyback weight, which is the sum of weights of all accounts.
     */
    function getTotalWeight() external view returns (uint256);

    /**
     * @notice Gets current Buyback index.
     * Its the accumulated sum of MNTs shares that are given for each weight of an account.
     */
    function getBuybackIndex() external view returns (uint256);

    /**
     * @notice Stakes the specified amount of MNT and transfers them to this contract.
     * Sender's weight would increase by the discounted amount of staked funds.
     * @notice This contract should be approved to transfer MNT from sender account
     * @param amount The amount of MNT to stake
     */
    function stake(uint256 amount) external;

    /**
     * @notice Unstakes the specified amount of MNT and transfers them back to sender if he participates
     *         in the Buyback system, otherwise just transfers MNT tokens to the sender.
     *         Sender's weight would decrease by discounted amount of unstaked funds, but resulting weight
     *         would not be greater than staked amount left. If `amount == MaxUint256` unstakes all staked tokens.
     * @param amount The amount of MNT to unstake
     */
    function unstake(uint256 amount) external;

    /**
     * @notice Claims buyback rewards, updates buyback weight and voting power.
     * Does nothing if account is not participating. Reverts if operation is paused.
     * @param account Address to update weights for
     */
    function updateBuybackAndVotingWeights(address account) external;

    /**
     * @notice Claims buyback rewards, updates buyback weight and voting power.
     * Does nothing if account is not participating or update is paused.
     * @param account Address to update weights for
     */
    function updateBuybackAndVotingWeightsRelaxed(address account) external;

    /**
     * @notice Does a buyback using the specified amount of MNT from sender's account
     * @param amount The amount of MNT to take and distribute as buyback
     * @dev RESTRICTION: Distributor only
     */
    function buyback(uint256 amount) external;

    /**
     * @notice Make account participating in the buyback. If the sender has a staked balance, then
     * the weight will be equal to the discounted amount of staked funds.
     */
    function participate() external;

    /**
     *@notice Make accounts participate in buyback before its start.
     * @param accounts Address to make participate in buyback.
     * @dev RESTRICTION: Admin only
     */
    function participateOnBehalf(address[] memory accounts) external;

    /**
     * @notice Leave buyback participation, claim any MNTs rewarded by the buyback.
     * Leaving does not withdraw staked MNTs but reduces weight of the account to zero
     */
    function leave() external;

    /**
     * @notice Leave buyback participation on behalf, claim any MNTs rewarded by the buyback and
     * reduce the weight of account to zero. All staked MNTs remain on the buyback contract and available
     * for their owner to be claimed
     * @dev Admin function to leave on behalf.
     * Can only be called if (timestamp > participantLastVoteTimestamp + maxNonVotingPeriod).
     * @param participant Address to leave for
     * @dev RESTRICTION: Admin only
     */
    function leaveOnBehalf(address participant) external;

    /**
     * @notice Leave buyback participation on behalf, claim any MNTs rewarded by the buyback and
     * reduce the weight of account to zero. All staked MNTs remain on the buyback contract and available
     * for their owner to be claimed.
     * @dev Function to leave sanctioned accounts from Buyback system
     * Can only be called if the participant is sanctioned by the AML system.
     * @param participant Address to leave for
     */
    function leaveByAmlDecision(address participant) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Minterest InterestRateModel Interface
 * @author Minterest
 */
interface IInterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @param protocolInterestFactorMantissa The current protocol interest factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest,
        uint256 protocolInterestFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

interface ILinkageRoot {
    /**
     * @notice Emitted when new root contract connected to all leafs
     */
    event LinkageRootSwitch(ILinkageRoot newRoot);

    /**
     * @notice Emitted when root interconnects its contracts
     */
    event LinkageRootInterconnected();

    /**
     * @notice Connects new root to all leafs contracts
     * @param newRoot New root contract address
     */
    function switchLinkageRoot(ILinkageRoot newRoot) external;

    /**
     * @notice Update root for all leaf contracts
     * @dev Should include only leaf contracts
     */
    function interconnect() external;
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