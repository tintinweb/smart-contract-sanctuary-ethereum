// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "../utils/Errors.sol";
import "../utils/UncheckedIncrement.sol";
import "../interfaces/ICafeStaking.sol";
import "../interfaces/IERC20StakingLocker.sol";
import "../interfaces/IERC721StakingLocker.sol";
import "../interfaces/IERC1155StakingLocker.sol";
import "../interfaces/ICafeAccumulator.sol";
import "./StakingCommons.sol";
import "./OnChainRewardsWallet.sol";

struct Stake {
    uint128 reward;
    uint128 paid;
    uint256 balance;
    uint256[50000] ids;
}

struct TokenRange {
    uint128 lower;
    uint128 upper;
    bool enabled;
}

struct Track {
    uint128 rewardPerTokenStored;
    uint128 lastUpdateTime;
    // unixtime stamp
    uint128 start;
    // unixtime stamp
    uint128 end;
    // the total of the Staking Asset deposited
    uint256 staked;
    // reward per second, in $CAFE
    uint256 rps;
    // valid token identity range (for ERC721 and ERC1155)
    TokenRange range;
    // unique track id
    uint32 id;
    /// @custom:security non-reentrant
    OnChainRewardsWallet wallet;
    // staking asset address
    address asset;
    // staking asset type
    TrackType atype;
    // if true, lock through asset transfer
    bool transferLock;
    // if true, prevent staking/unstaking
    bool paused;
}

contract CafeStakingV21 is
    ICafeStaking,
    Initializable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IERC20StakingLocker;
    using UncheckedIncrement for uint256;

    /// @custom:security non-reentrant
    IERC20Upgradeable public cafeToken;

    mapping(uint256 => Track) public tracks;

    uint256 public tracksCount;

    // staker => asset => Stake
    mapping(address => mapping(address => Stake)) public stakes;

    /* ========== INITIALIZER ========== */

    function initialize(address cafeToken_) external initializer {
        if (!cafeToken_.isContract())
            revert ContractAddressExpected(cafeToken_);

        __Ownable_init();

        cafeToken = IERC20Upgradeable(cafeToken_);
    }

    /* ========== PUBLIC MUTATORS ========== */

    /// @dev Batch process Stake Requests.
    /// @param msr Multiple stake requests.
    /// @param actions Multiple corresponding actions.
    function execute(
        StakeRequest[] calldata msr,
        StakeAction[][] calldata actions
    ) external {
        _execute(msg.sender, msr, actions);
    }

    /// @dev Batch process Stake Requests. For autostaking purposes,
    ///      so only callable from asset contracts.
    /// @param msr Multiple stake requests.
    /// @param actions Multiple corresponding actions.
    function execute4(
        address account,
        StakeRequest[] calldata msr,
        StakeAction[][] calldata actions
    ) external {
        if (msg.sender != tracks[msr[0].trackId].asset) revert Unauthorized();

        _execute(account, msr, actions);
    }

    /* ========== ADMIN-ONLY MUTATORS ========== */

    /// @dev Create a staking track. Assign id automatically. Emit {TrackCreated} on success.
    ///      Transfers staking rewards to the track's On-Chain Rewards Wallet.
    ///
    /// @param asset Stakable asset address.
    /// @param totalRewards Total $CAFE to allocate (from address(this)'s balance.)
    /// @param atype Asset type.
    /// @param start Begin rewards accrual at this time.
    /// @param end Expire the track at this time.
    /// @param lower Set the lower token range boundary.
    ///        Disable token range by making `lower` higher than `upper`.
    /// @param upper Set the upper token range boundary.
    /// @param transferLock Define the track as custodial (with `true`.)
    ///
    /// Requirements:
    /// - Caller must be the contract owner.
    /// - `asset` must be a contract.
    /// - `totalRewards` must be positive.
    /// - CafeStaking must hold at least `totalRewards` of $CAFE
    /// - `start` must be in the future
    /// - `end` must exceed start
    function createTrack(
        address asset,
        uint256 totalRewards,
        TrackType atype,
        uint256 start,
        uint256 end,
        uint256 lower,
        uint256 upper,
        bool transferLock
    ) external {
        _onlyOwner();

        if (!asset.isContract()) revert ContractAddressExpected(asset);
        if (totalRewards == 0) revert ZeroAmount();
        if (end <= start) revert InvalidTrackTiming();
        if (block.timestamp >= start) revert InvalidTrackStart();

        address thisContract = address(this);

        if (cafeToken.balanceOf(thisContract) < totalRewards)
            revert InsufficientCAFE();

        Track storage track = tracks[tracksCount];

        track.wallet = new OnChainRewardsWallet(thisContract);
        track.asset = asset;
        track.rps = totalRewards / (end - start);

        if (upper >= lower) {
            track.range = TokenRange(uint128(lower), uint128(upper), true);
        }

        track.start = uint128(start);
        track.end = uint128(end);
        track.atype = atype;
        track.transferLock = transferLock;
        track.id = uint32(tracksCount);

        emit TrackCreated(tracksCount, asset, track.rps);

        tracksCount++;

        track.wallet.approve(address(cafeToken), thisContract, true);
        cafeToken.safeTransfer(address(track.wallet), totalRewards);
    }

    /// @dev Pause/resume an existing track. Emit {TrackToggled} on success.
    /// @param trackId Identity of the track to pause/resume.
    ///
    /// Requirements:
    /// - Caller must be the contract owner
    /// - The track in question must exist
    function toggleTrack(uint256 trackId) external {
        _onlyOwner();

        _trackExists(trackId);

        Track storage track = tracks[trackId];

        track.paused = !track.paused;

        emit TrackToggled(track.id, track.paused);
    }

    /// @dev Transfer an amount of $CAFE from the contract's balance to a track's wallet.
    ///      Automatically update the track's RPS.
    /// @param trackId The destination track.
    /// @param amount The amount to transfer.
    ///
    /// Requirements:
    /// - The track in question must exist.
    /// - The track in question must be non-expired.
    /// - The amount must be positive.
    /// - CafeStaking must hold at least `amount` of $CAFE
    function replenishTrack(uint256 trackId, uint256 amount) external {
        _onlyOwner();
        _trackExists(trackId);

        _replenishTrack(trackId, amount, false);
    }

    /// @dev Pull all the accumulated $CAFE from an external accumulator asset
    ///      and transfer it to a track's wallet.
    /// @param trackId The destination track.
    /// @param accumulator The accumulator asset address.
    ///
    /// Requirements:
    /// - The track in question must exist.
    /// - The track in question must be non-expired.
    /// - The amount pulled must be positive.
    function replenishTrackFrom(uint256 trackId, address accumulator) external {
        _onlyOwner();
        _trackExists(trackId);

        Track storage track = tracks[trackId];

        _replenishTrack(
            trackId,
            ICafeAccumulator(accumulator).pull(address(track.wallet)),
            true
        );
    }

    /* ========== VIEWS ========== */

    /// @dev Get staked balance of an account for a given ERC20 track.
    /// @param trackId The track (asset) to read from.
    /// @param account The account to fetch the balance for.
    ///
    /// Requirements:
    /// - The track in question must exist
    function stakeInfoERC20(uint256 trackId, address account)
        external
        view
        returns (uint256 bal)
    {
        _trackExists(trackId);

        Track storage track = tracks[trackId];

        if (track.transferLock) {
            bal = stakes[account][track.asset].balance;
        } else {
            bal = IERC20StakingLocker(track.asset).locked(account);
        }
    }

    /// @dev Get token identities and balance of an account for a given ERC721 track.
    /// @param trackId The track (asset) to read from.
    /// @param account The account to fetch the balance for.
    /// @param page Read data starting at the top of this page.
    /// @param records Records per page.
    ///
    /// Requirements:
    /// - The track in question must exist
    function stakeInfoERC721(
        uint256 trackId,
        address account,
        uint256 page,
        uint256 records
    ) external view returns (uint256[] memory, uint256) {
        _trackExists(trackId);

        Track storage track = tracks[trackId];
        uint256 from = page * records;
        uint256 to = from + records;
        uint256[] memory result = new uint256[](records);
        bool transferLock = track.transferLock;

        for (uint256 r = from; r < to; r = r.inc()) {
            uint256 amount = transferLock
                ? stakes[account][track.asset].ids[r]
                : (IERC721StakingLocker(track.asset).isLocked(r) &&
                    IERC721StakingLocker(track.asset).ownerOf(r) == account)
                ? 1
                : 0;

            if (amount > 0) {
                result[r - from] = 1;
            }
        }

        return (result, stakes[account][track.asset].balance);
    }

    /// Get token identities, token count, and balance of an account for a given ERC1155 track.
    /// @param trackId The track (asset) to read from.
    /// @param account The account to fetch the balance for.
    /// @param page Read data starting at the top of this page.
    /// @param records Records per page.
    ///
    /// Requirements:
    /// - The track in question must exist
    function stakeInfoERC1155(
        uint256 trackId,
        address account,
        uint256 page,
        uint256 records
    )
        external
        view
        returns (
            uint256[] memory,
            uint256,
            uint256
        )
    {
        _trackExists(trackId);

        Track storage track = tracks[trackId];
        uint256 from = page * records;
        uint256 to = from + records;

        uint256[] memory result = new uint256[](records);
        bool transferLock = track.transferLock;
        uint256 count = 0;

        for (uint256 r = from; r < to; r = r.inc()) {
            uint256 amount = transferLock
                ? stakes[account][track.asset].ids[r]
                : IERC1155StakingLocker(track.asset).locked(account, r);

            if (amount > 0) {
                count += amount;
                result[r - from] = amount;
            }
        }
        return (result, count, stakes[account][track.asset].balance);
    }

    /// @dev Get yield per token.
    function rewardPerToken(uint256 trackId) public view returns (uint256) {
        _trackExists(trackId);

        Track storage track = tracks[trackId];

        if (track.staked == 0) {
            return 0;
        }

        return
            track.rewardPerTokenStored +
            ((track.rps *
                (_restrictedBlockTimestamp(track.end) - track.lastUpdateTime)) /
                track.staked);
    }

    /// @dev Get the amount earned
    function earned(uint256 trackId, address account)
        public
        view
        returns (uint256 res)
    {
        _trackExists(trackId);

        Track storage track = tracks[trackId];

        Stake storage stake_ = stakes[account][track.asset];

        uint256 balance;

        if (track.atype == TrackType.ERC20) {
            balance = track.transferLock
                ? stake_.balance
                : IERC20StakingLocker(track.asset).locked(account);
        } else {
            balance = stake_.balance;
        }

        if (balance == 0) {
            res = stake_.reward;
        } else {
            res =
                balance *
                (rewardPerToken(trackId) - stake_.paid) +
                stake_.reward;
        }
    }

    /* ========== INTERNALS/MODIFIERS ========== */

    function _replenishTrack(
        uint256 trackId,
        uint256 amount,
        bool directTransfer
    ) internal {
        if (amount == 0) revert ZeroAmount();

        Track storage track = tracks[trackId];

        if (!directTransfer && (cafeToken.balanceOf(address(this)) < amount))
            revert InsufficientCAFE();

        if (block.timestamp >= track.end) revert TrackExpired();

        uint256 newBalance = cafeToken.balanceOf(address(track.wallet)) +
            (directTransfer ? 0 : amount);

        track.rps = newBalance / (track.end - block.timestamp);

        emit TrackReplenished(trackId, amount, track.rps);

        if (!directTransfer)
            cafeToken.safeTransfer(address(track.wallet), amount);
    }

    function _execute(
        address account,
        StakeRequest[] calldata msr,
        StakeAction[][] calldata actions
    ) internal {
        for (uint256 sr = 0; sr < msr.length; sr = sr.inc()) {
            _trackExists(msr[sr].trackId);
        }

        for (uint256 sr = 0; sr < msr.length; sr = sr.inc()) {
            Track storage track = tracks[msr[sr].trackId];
            _updateRewards(track, account);

            for (uint256 a = 0; a < actions[sr].length; a = a.inc()) {
                if (actions[sr][a] == StakeAction.Stake) {
                    _stake(account, tracks[msr[sr].trackId], msr[sr]);
                } else if (actions[sr][a] == StakeAction.Unstake) {
                    _unstake(account, tracks[msr[sr].trackId], msr[sr]);
                } else {
                    _collect(account, tracks[msr[sr].trackId]);
                }
            }
        }
    }

    function _stake(
        address account,
        Track storage track,
        StakeRequest calldata sr
    ) internal {
        _inStakingPeriod(track);

        if (track.atype == TrackType.ERC20) {
            _stake(account, track, sr.amounts[0]);
        } else if (track.atype == TrackType.ERC1155) {
            _stake(account, track, sr.ids, sr.amounts);
        } else {
            // TrackType.ERC721
            _stake(account, track, sr.ids);
        }
    }

    function _unstake(
        address account,
        Track storage track,
        StakeRequest calldata sr
    ) internal {
        if (track.atype == TrackType.ERC20) {
            _unstake(account, track, sr.amounts[0]);
        } else if (track.atype == TrackType.ERC1155) {
            _unstake(account, track, sr.ids, sr.amounts);
        } else {
            // TrackType.ERC721
            _unstake(account, track, sr.ids);
        }
    }

    // ERC20
    function _stake(
        address account,
        Track storage track,
        uint256 amount
    ) internal {
        _whenNotPaused(track);
        _erc20StakeRequestValid(amount);

        IERC20StakingLocker erc20_ = IERC20StakingLocker(track.asset);

        track.staked += amount;

        emit AssetStaked(track.asset, account, amount);

        if (track.transferLock) {
            Stake storage stake_ = stakes[account][track.asset];
            stake_.balance += amount;

            erc20_.safeTransferFrom(account, address(this), amount);
        } else {
            erc20_.lock(account, amount);
        }
    }

    // ERC1155
    function _stake(
        address account,
        Track storage track,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal {
        _whenNotPaused(track);
        _erc1155StakeRequestValid(track, ids, amounts);

        uint256 subtotal;
        Stake storage stake_ = stakes[account][track.asset];

        IERC1155StakingLocker erc1155_ = IERC1155StakingLocker(track.asset);

        for (uint256 t = 0; t < ids.length; t = t.inc()) {
            stake_.ids[ids[t]] += amounts[t];
            subtotal += amounts[t];
        }

        stake_.balance += subtotal;
        track.staked += subtotal;

        emit AssetStaked(track.asset, account, subtotal);

        if (track.transferLock) {
            erc1155_.safeBatchTransferFrom(
                account,
                address(this),
                ids,
                amounts,
                ""
            );
        } else {
            erc1155_.lock(account, ids, amounts);
        }
    }

    // ERC721
    function _stake(
        address account,
        Track storage track,
        uint256[] calldata ids
    ) internal {
        _whenNotPaused(track);
        _erc721StakeRequestValid(track, ids);

        Stake storage stake_ = stakes[account][track.asset];
        emit AssetStaked(track.asset, account, ids.length);
        IERC721StakingLocker erc721_ = IERC721StakingLocker(track.asset);

        stake_.balance += ids.length;
        track.staked += ids.length;

        if (track.transferLock) {
            for (uint256 t = 0; t < ids.length; t = t.inc()) {
                stake_.ids[ids[t]] = 1;
                erc721_.safeTransferFrom(account, address(this), ids[t]);
            }
        } else {
            erc721_.lock(account, ids);
        }
    }

    // ERC20
    function _unstake(
        address account,
        Track storage track,
        uint256 amount
    ) internal {
        _whenNotPaused(track);
        _erc20StakeRequestValid(amount);

        IERC20StakingLocker erc20_ = IERC20StakingLocker(track.asset);

        if (amount > track.staked) revert AmountExceedsLocked();

        track.staked -= amount;

        emit AssetUnstaked(track.asset, account, amount);

        if (track.transferLock) {
            Stake storage stake_ = stakes[account][track.asset];
            if (amount > stake_.balance) revert AmountExceedsLocked();

            stake_.balance -= amount;

            erc20_.safeTransfer(account, amount);
        } else {
            // will revert on insufficient balance
            erc20_.unlock(account, amount);
        }
    }

    // ERC1155
    function _unstake(
        address account,
        Track storage track,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal {
        _whenNotPaused(track);
        _erc1155StakeRequestValid(track, ids, amounts);

        uint256 subtotal;
        Stake storage stake_ = stakes[account][track.asset];

        IERC1155StakingLocker erc1155_ = IERC1155StakingLocker(track.asset);

        for (uint256 t = 0; t < ids.length; t = t.inc()) {
            if (stake_.ids[ids[t]] < amounts[t]) revert AmountExceedsLocked();

            stake_.ids[ids[t]] -= amounts[t];
            subtotal += amounts[t];
        }

        stake_.balance -= subtotal;
        track.staked -= subtotal;

        emit AssetUnstaked(track.asset, account, subtotal);

        if (track.transferLock) {
            erc1155_.safeBatchTransferFrom(
                address(this),
                account,
                ids,
                amounts,
                ""
            );
        } else {
            erc1155_.unlock(account, ids, amounts);
        }
    }

    // ERC721
    function _unstake(
        address account,
        Track storage track,
        uint256[] calldata ids
    ) internal {
        _whenNotPaused(track);
        _erc721StakeRequestValid(track, ids);

        Stake storage stake_ = stakes[account][track.asset];
        IERC721StakingLocker erc721_ = IERC721StakingLocker(track.asset);

        if (stake_.balance < ids.length || track.staked < ids.length)
            revert AmountExceedsLocked();

        stake_.balance -= ids.length;
        track.staked -= ids.length;

        emit AssetUnstaked(track.asset, account, ids.length);

        if (track.transferLock) {
            for (uint256 t = 0; t < ids.length; t = t.inc()) {
                if (stake_.ids[ids[t]] != 1) revert TokenNotOwn();

                delete stake_.ids[ids[t]];

                erc721_.safeTransferFrom(address(this), account, ids[t]);
            }
        } else {
            erc721_.unlock(account, ids);
        }
    }

    function _collect(address account, Track storage track) internal {
        _whenNotPaused(track);
        Stake storage stake_ = stakes[account][track.asset];
        uint256 reward = stake_.reward;

        if (reward > 0) {
            stake_.reward = 0;
            emit RewardPaid(account, reward);
            cafeToken.safeTransferFrom(address(track.wallet), account, reward);
        }
    }

    function _updateRewards(Track storage track, address account) internal {
        uint128 rewardPerTokenStored = uint128(rewardPerToken(track.id));

        track.rewardPerTokenStored = rewardPerTokenStored;
        track.lastUpdateTime = _restrictedBlockTimestamp(track.end);
        Stake storage stake_ = stakes[account][track.asset];
        stake_.reward = uint128(earned(track.id, account));
        stake_.paid = rewardPerTokenStored;
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }

    function _whenNotPaused(Track storage track) internal view {
        if (track.paused) revert TrackPaused(track.id);
    }

    function _trackExists(uint256 trackId) internal view {
        if (trackId >= tracksCount) revert UnknownTrack();
    }

    function _inStakingPeriod(Track storage track) internal view {
        if (!(block.timestamp >= track.start && block.timestamp <= track.end))
            revert NotInStakingPeriod();
    }

    function _restrictedBlockTimestamp(uint128 trackEnd)
        internal
        view
        returns (uint128)
    {
        uint256 blockstamp = block.timestamp;
        return (blockstamp <= trackEnd) ? uint128(blockstamp) : trackEnd;
    }

    function _erc20StakeRequestValid(uint256 amount) internal pure {
        if (amount == 0) revert ZeroAmount();
    }

    function _erc1155StakeRequestValid(
        Track storage track,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal view {
        if (ids.length != amounts.length) revert InvalidArrayLength();
        if (ids.length == 0) revert NoTokensGiven();

        if (track.range.enabled) {
            _checkRange(ids, track.range.lower, track.range.upper);
        }
    }

    function _erc721StakeRequestValid(
        Track storage track,
        uint256[] calldata ids
    ) internal view {
        if (ids.length == 0) revert NoTokensGiven();

        if (track.range.enabled) {
            _checkRange(ids, track.range.lower, track.range.upper);
        }
    }

    function _checkRange(
        uint256[] calldata ids,
        uint128 lower,
        uint128 upper
    ) internal view {
        for (uint256 t = 0; t < ids.length; t = t.inc()) {
            if (ids[t] < lower || ids[t] > upper) revert TokenOutOfRange();
        }
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        interfaceId;
        return false;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        id;
        value;
        data;
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        ids;
        values;
        data;
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

pragma solidity 0.8.13;

error Unauthorized();

error InvalidArrayLength();

error InvalidMerkleProof();

error ZeroAddress();

error ZeroAmount();

error ZeroPrice();

error ContractAddressExpected(address contract_);

error InsufficientCAFE();

error InsufficientBalance();

error UnknownTrack();

error TokenLocked();

error TokenNotOwn();

error UnknownToken();

error TrackExpired();

error TokenNotLocked();

error NoTokensGiven();

error TokenOutOfRange();

error AmountExceedsLocked();

error StakingVolumeExceeded();

error StakingTrackNotAssigned();

error StakingLockViolation(uint256 tokenId);

error NotInStakingPeriod();

error TrackPaused(uint256 trackId);

error ContractPaused();

error VSExistsForAccount(address account);

error VSInvalidCliff();

error VSInvalidAllocation();

error VSMissing(address account);

error VSCliffNotReached();

error VSInvalidPeriodSpec();

error VSCliffNERelease();

error NothingVested();

error OnceOnly();

error MintingExceedsSupply(uint256 supply);

error InvalidStage();

error DuplicateClaim();

error DuplicateTokenSelection();
error CantCreateZeroTokens();
error TokenCollectionMismatch();
error CollectionNotFound();
error InvalidETHAmount();
error TokenMaxSupplyReached();
error InOpenSale();
error NotInOpenSale();
error InvalidEditionsSpec();
error ZeroEditionsSpecified();

error InvalidTrackTiming();
error InvalidTrackStart();

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

library UncheckedIncrement {
    function inc(uint256 i) internal pure returns (uint256) {
        unchecked { return  i + 1; }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../staking/StakingCommons.sol";

interface ICafeStaking {
    /**
     * @dev Emitted when a track is created that will distribute `rewards` $CAFE to holders of `asset`.
     */
    event TrackCreated(
        uint256 indexed id,
        address indexed asset,
        uint256 indexed rps
    );

    /**
     * @dev Emitted when a track is toggled (paused or resumed).
     */
    event TrackToggled(uint256 indexed id, bool indexed newState);

    /**
     * @dev Emitted when a track's reward balance is replenished.
     *
     */
    event TrackReplenished(
        uint256 indexed id,
        uint256 indexed amount,
        uint256 indexed newRps
    );

    /**
     * @dev Emitted when a track's reward balance is reduced.
     *
     */
    event TrackReduced(
        uint256 indexed id,
        uint256 indexed amount,
        uint256 indexed newRps
    ); 

    /**
     * @dev Emitted when an asset is staked.
     */
    event AssetStaked(address indexed asset, address account, uint256 amount);

    /**
     * @dev Emitted when an asset is unstaked.
     */
    event AssetUnstaked(address indexed asset, address account, uint256 amount);

    /**
     * @dev Emitted when `reward` tokens are claimed by `account`.
     */
    event RewardPaid(address indexed account, uint256 indexed reward);

    function createTrack(
        address asset,
        uint256 rewardsAmount,
        TrackType atype,
        uint256 start,
        uint256 end,
        uint256 lower,
        uint256 upper,
        bool transferLock
    ) external;

    function replenishTrack(uint256 trackId, uint256 amount) external;

    function toggleTrack(uint256 trackId) external;

    function execute(
        StakeRequest[] calldata msr,
        StakeAction[][] calldata actions
    ) external;

    function execute4(
        address account,
        StakeRequest[] calldata msr,
        StakeAction[][] calldata actions
    ) external;

    function rewardPerToken(uint256 trackId) external view returns (uint256);

    function earned(uint256 trackId, address account)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20StakingLocker is IERC20Upgradeable {
    function lock(address, uint256) external;

    function unlock(address, uint256) external;

    function locked(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IERC721StakingLocker is IERC721Upgradeable {
    function lock(address, uint256[] memory) external;

    function unlock(address, uint256[] memory) external;

    function isLocked(uint256) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC1155StakingLocker is IERC1155Upgradeable {
    function lock(
        address,
        uint256[] memory,
        uint256[] memory
    ) external;

    function unlock(
        address,
        uint256[] memory,
        uint256[] memory
    ) external;

    function locked(address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ICafeAccumulator {
    function pull(address) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

struct StakeRequest {
    uint256 trackId;
    uint256[] ids;
    uint256[] amounts;   
}

enum StakeAction {
    Stake,
    Unstake,
    Collect
}

enum TrackType {
    ERC20,
    ERC1155,
    ERC721
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/Errors.sol";

contract OnChainRewardsWallet {
    address private _owner;

    constructor(address owner_) {
        _owner = owner_;
    }

    function approve(
        address asset,
        address contract_,
        bool enable
    ) external {
        _onlyOwner();
        if (enable) {
            IERC20(asset).approve(contract_, type(uint256).max - 1);
        } else {
            IERC20(asset).approve(contract_, 0);
        }
    }

    function _onlyOwner() internal view {
        if (msg.sender != _owner) revert Unauthorized();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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