// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Drips, DripsConfig, DripsConfigImpl, DripsReceiver} from "./Drips.sol";
import {IReserve} from "./Reserve.sol";
import {Managed} from "./Managed.sol";
import {Splits, SplitsReceiver} from "./Splits.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/// @notice Drips hub contract. Automatically drips and splits funds between users.
///
/// The user can transfer some funds to their drips balance in the contract
/// and configure a list of receivers, to whom they want to drip these funds.
/// As soon as the drips balance is enough to cover at least 1 second of dripping
/// to the configured receivers, the funds start dripping automatically.
/// Every second funds are deducted from the drips balance and moved to their receivers.
/// The process stops automatically when the drips balance is not enough to cover another second.
///
/// Every user has a receiver balance, in which they have funds received from other users.
/// The dripped funds are added to the receiver balances in global cycles.
/// Every `cycleSecs` seconds the drips hub adds dripped funds to the receivers' balances,
/// so recently dripped funds may not be receivable immediately.
/// `cycleSecs` is a constant configured when the drips hub is deployed.
/// The receiver balance is independent from the drips balance,
/// to drip received funds they need to be first collected and then added to the drips balance.
///
/// The user can share collected funds with other users by using splits.
/// When collecting, the user gives each of their splits receivers a fraction of the received funds.
/// Funds received from splits are available for collection immediately regardless of the cycle.
/// They aren't exempt from being split, so they too can be split when collected.
/// Users can build chains and networks of splits between each other.
/// Anybody can request collection of funds for any user,
/// which can be used to enforce the flow of funds in the network of splits.
///
/// The concept of something happening periodically, e.g. every second or every `cycleSecs` are
/// only high-level abstractions for the user, Ethereum isn't really capable of scheduling work.
/// The actual implementation emulates that behavior by calculating the results of the scheduled
/// events based on how many seconds have passed and only when the user needs their outcomes.
///
/// The contract assumes that all amounts in the system can be stored in signed 128-bit integers.
/// It's guaranteed to be safe only when working with assets with supply lower than `2 ^ 127`.
contract DripsHub is Managed {
    /// @notice The address of the ERC-20 reserve which the drips hub works with
    IReserve public immutable reserve;
    /// @notice On every timestamp `T`, which is a multiple of `cycleSecs`, the receivers
    /// gain access to drips received during `T - cycleSecs` to `T - 1`.
    uint32 public immutable cycleSecs;
    /// @notice Maximum number of drips receivers of a single user.
    /// Limits cost of changes in drips configuration.
    uint8 public immutable maxDripsReceivers;
    /// @notice Maximum number of splits receivers of a single user.
    /// Limits cost of collecting.
    uint32 public immutable maxSplitsReceivers;
    /// @notice The total splits weight of a user
    uint32 public immutable totalSplitsWeight;
    /// @notice The offset of the controlling app ID in the user ID.
    /// In other words the controlling app ID is the higest 32 bits of the user ID.
    uint256 public constant APP_ID_OFFSET = 224;
    /// @notice The ERC-1967 storage slot holding a single `DripsHubStorage` structure.
    bytes32 private immutable storageSlot = erc1967Slot("eip1967.dripsHub.storage");

    /// @notice Emitted when an app is registered
    /// @param appId The app ID
    /// @param appAddr The app address
    event AppRegistered(uint32 indexed appId, address indexed appAddr);

    /// @notice Emitted when an app address is updated
    /// @param appId The app ID
    /// @param oldAppAddr The old app address
    /// @param newAppAddr The new app address
    event AppAddressUpdated(
        uint32 indexed appId,
        address indexed oldAppAddr,
        address indexed newAppAddr
    );

    struct DripsHubStorage {
        /// @notice The drips storage
        Drips.Storage drips;
        /// @notice The splits storage
        Splits.Storage splits;
        /// @notice The next app ID that will be used when registering.
        uint32 nextAppId;
        /// @notice App addresses. The key is the app ID, the value is the app address.
        mapping(uint32 => address) appAddrs;
    }

    /// @param _cycleSecs The length of cycleSecs to be used in the contract instance.
    /// Low value makes funds more available by shortening the average time of funds being frozen
    /// between being taken from the users' drips balances and being receivable by their receivers.
    /// High value makes receiving cheaper by making it process less cycles for a given time range.
    /// @param _reserve The address of the ERC-20 reserve which the drips hub will work with
    constructor(uint32 _cycleSecs, IReserve _reserve) {
        require(_cycleSecs > 1, "Cycle length too low");
        cycleSecs = _cycleSecs;
        maxDripsReceivers = Drips.MAX_DRIPS_RECEIVERS;
        maxSplitsReceivers = Splits.MAX_SPLITS_RECEIVERS;
        totalSplitsWeight = Splits.TOTAL_SPLITS_WEIGHT;
        reserve = _reserve;
    }

    /// @notice A modifier making functions callable only by the app controlling the user ID.
    /// @param userId The user ID.
    modifier onlyApp(uint256 userId) {
        uint32 appId = uint32(userId >> APP_ID_OFFSET);
        _assertCallerIsApp(appId);
        _;
    }

    function _assertCallerIsApp(uint32 appId) internal view {
        require(appAddress(appId) == msg.sender, "Callable only by the app");
    }

    /// @notice Registers an app.
    /// The app is assigned a unique ID and a range of user IDs it can control.
    /// That range consists of all 2^224 user IDs with highest 32 bits equal to the app ID.
    /// Multiple apps can have the same address, it can then control all of them.
    /// @return appId The registered app ID.
    function registerApp(address appAddr) public whenNotPaused returns (uint32 appId) {
        DripsHubStorage storage dripsHubStorage = _dripsHubStorage();
        appId = dripsHubStorage.nextAppId++;
        dripsHubStorage.appAddrs[appId] = appAddr;
        emit AppRegistered(appId, appAddr);
    }

    /// @notice Returns the app address.
    /// @param appId The app ID to look up.
    /// @return appAddr The address of the app.
    /// If the app hasn't been registered yet, returns address 0.
    function appAddress(uint32 appId) public view returns (address appAddr) {
        return _dripsHubStorage().appAddrs[appId];
    }

    /// @notice Updates the app address. Must be called from the current app address.
    /// @param appId The app ID.
    /// @param newAppAddr The new address of the app.
    function updateAppAddress(uint32 appId, address newAppAddr) public whenNotPaused {
        _assertCallerIsApp(appId);
        _dripsHubStorage().appAddrs[appId] = newAppAddr;
        emit AppAddressUpdated(appId, msg.sender, newAppAddr);
    }

    /// @notice Returns the app ID which will be assigned for the next registered app.
    /// @return appId The next app ID.
    function nextAppId() public view returns (uint32 appId) {
        return _dripsHubStorage().nextAppId;
    }

    /// @notice Returns amount of received funds available for collection for a user.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collectedAmt The collected amount
    /// @return splitAmt The amount split to the user's splits receivers
    function collectableAll(
        uint256 userId,
        IERC20 erc20,
        SplitsReceiver[] memory currReceivers
    ) public view returns (uint128 collectedAmt, uint128 splitAmt) {
        uint256 assetId = _assetId(erc20);
        // Receivable from cycles
        (uint128 receivedAmt, ) = Drips.receivableDrips(
            _dripsHubStorage().drips,
            cycleSecs,
            userId,
            assetId,
            type(uint32).max
        );
        // Collectable independently from cycles
        receivedAmt += Splits.splittable(_dripsHubStorage().splits, userId, assetId);
        // Split when collected
        (collectedAmt, splitAmt) = Splits.splitResults(
            _dripsHubStorage().splits,
            userId,
            currReceivers,
            receivedAmt
        );
        // Already split
        collectedAmt += Splits.collectable(_dripsHubStorage().splits, userId, assetId);
    }

    /// @notice Collects all received funds available for the user
    /// and transfers them out of the drips hub contract to msg.sender.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collectedAmt The collected amount
    /// @return splitAmt The amount split to the user's splits receivers
    function collectAll(
        uint256 userId,
        IERC20 erc20,
        SplitsReceiver[] memory currReceivers
    ) public whenNotPaused returns (uint128 collectedAmt, uint128 splitAmt) {
        receiveDrips(userId, erc20, type(uint32).max);
        (, splitAmt) = split(userId, erc20, currReceivers);
        collectedAmt = collect(userId, erc20);
    }

    /// @notice Counts cycles from which drips can be collected.
    /// This function can be used to detect that there are
    /// too many cycles to analyze in a single transaction.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token
    /// @return cycles The number of cycles which can be flushed
    function receivableDripsCycles(uint256 userId, IERC20 erc20)
        public
        view
        returns (uint32 cycles)
    {
        return
            Drips.receivableDripsCycles(
                _dripsHubStorage().drips,
                cycleSecs,
                userId,
                _assetId(erc20)
            );
    }

    /// @notice Calculate effects of calling `receiveDrips` with the given parameters.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token
    /// @param maxCycles The maximum number of received drips cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivableAmt The amount which would be received
    /// @return receivableCycles The number of cycles which would still be receivable after the call
    function receivableDrips(
        uint256 userId,
        IERC20 erc20,
        uint32 maxCycles
    ) public view returns (uint128 receivableAmt, uint32 receivableCycles) {
        return
            Drips.receivableDrips(
                _dripsHubStorage().drips,
                cycleSecs,
                userId,
                _assetId(erc20),
                maxCycles
            );
    }

    /// @notice Receive drips for the user.
    /// Received drips cycles won't need to be analyzed ever again.
    /// Calling this function does not collect but makes the funds ready to be split and collected.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token
    /// @param maxCycles The maximum number of received drips cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivedAmt The received amount
    /// @return receivableCycles The number of cycles which still can be received
    function receiveDrips(
        uint256 userId,
        IERC20 erc20,
        uint32 maxCycles
    ) public whenNotPaused returns (uint128 receivedAmt, uint32 receivableCycles) {
        uint256 assetId = _assetId(erc20);
        (receivedAmt, receivableCycles) = Drips.receiveDrips(
            _dripsHubStorage().drips,
            cycleSecs,
            userId,
            assetId,
            maxCycles
        );
        if (receivedAmt > 0) {
            Splits.give(_dripsHubStorage().splits, userId, userId, assetId, receivedAmt);
        }
    }

    /// @notice Returns user's received but not split yet funds.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// @return amt The amount received but not split yet.
    function splittable(uint256 userId, IERC20 erc20) public view returns (uint128 amt) {
        return Splits.splittable(_dripsHubStorage().splits, userId, _assetId(erc20));
    }

    /// @notice Splits user's received but not split yet funds among receivers.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collectableAmt The amount made collectable for the user
    /// on top of what was collectable before.
    /// @return splitAmt The amount split to the user's splits receivers
    function split(
        uint256 userId,
        IERC20 erc20,
        SplitsReceiver[] memory currReceivers
    ) public whenNotPaused returns (uint128 collectableAmt, uint128 splitAmt) {
        return Splits.split(_dripsHubStorage().splits, userId, _assetId(erc20), currReceivers);
    }

    /// @notice Returns user's received funds already split and ready to be collected.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token.
    /// @return amt The collectable amount.
    function collectable(uint256 userId, IERC20 erc20) public view returns (uint128 amt) {
        return Splits.collectable(_dripsHubStorage().splits, userId, _assetId(erc20));
    }

    /// @notice Collects user's received already split funds
    /// and transfers them out of the drips hub contract to msg.sender.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token
    /// @return amt The collected amount
    function collect(uint256 userId, IERC20 erc20)
        public
        whenNotPaused
        onlyApp(userId)
        returns (uint128 amt)
    {
        amt = Splits.collect(_dripsHubStorage().splits, userId, _assetId(erc20));
        reserve.withdraw(erc20, msg.sender, amt);
    }

    /// @notice Gives funds from the user to the receiver.
    /// The receiver can split and collect them immediately.
    /// Transfers the funds to be given from the user's wallet to the drips hub contract.
    /// @param userId The user ID
    /// @param receiver The receiver
    /// @param erc20 The used ERC-20 token
    /// @param amt The given amount
    function give(
        uint256 userId,
        uint256 receiver,
        IERC20 erc20,
        uint128 amt
    ) public whenNotPaused onlyApp(userId) {
        Splits.give(_dripsHubStorage().splits, userId, receiver, _assetId(erc20), amt);
        reserve.deposit(erc20, msg.sender, amt);
    }

    /// @notice Current user drips state.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token
    /// @return dripsHash The current drips receivers list hash, see `hashDrips`
    /// @return updateTime The time when drips have been configured for the last time
    /// @return balance The balance when drips have been configured for the last time
    function dripsState(uint256 userId, IERC20 erc20)
        public
        view
        returns (
            bytes32 dripsHash,
            uint32 updateTime,
            uint128 balance,
            uint32 defaultEnd
        )
    {
        return Drips.dripsState(_dripsHubStorage().drips, userId, _assetId(erc20));
    }

    /// @notice User drips balance at a given timestamp
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token
    /// @param receivers The current drips receivers list
    /// @param timestamp The timestamps for which balance should be calculated.
    /// It can't be lower than the timestamp of the last call to `setDrips`.
    /// If it's bigger than `block.timestamp`, then it's a prediction assuming
    /// that `setDrips` won't be called before `timestamp`.
    /// @return balance The user balance on `timestamp`
    function balanceAt(
        uint256 userId,
        IERC20 erc20,
        DripsReceiver[] memory receivers,
        uint32 timestamp
    ) public view returns (uint128 balance) {
        return
            Drips.balanceAt(
                _dripsHubStorage().drips,
                userId,
                _assetId(erc20),
                receivers,
                timestamp
            );
    }

    /// @notice Sets the user's drips configuration.
    /// Transfers funds between the user's wallet and the drips hub contract
    /// to fulfill the change of the drips balance.
    /// @param userId The user ID
    /// @param erc20 The used ERC-20 token
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The drips balance change to be applied.
    /// Positive to add funds to the drips balance, negative to remove them.
    /// @param newReceivers The list of the drips receivers of the user to be set.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @return newBalance The new drips balance of the user.
    /// @return realBalanceDelta The actually applied drips balance change.
    function setDrips(
        uint256 userId,
        IERC20 erc20,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers
    ) public whenNotPaused onlyApp(userId) returns (uint128 newBalance, int128 realBalanceDelta) {
        (newBalance, realBalanceDelta) = Drips.setDrips(
            _dripsHubStorage().drips,
            cycleSecs,
            userId,
            _assetId(erc20),
            currReceivers,
            balanceDelta,
            newReceivers
        );
        if (realBalanceDelta > 0) {
            reserve.deposit(erc20, msg.sender, uint128(realBalanceDelta));
        } else if (realBalanceDelta < 0) {
            reserve.withdraw(erc20, msg.sender, uint128(-realBalanceDelta));
        }
    }

    /// @notice Calculates the hash of the drips configuration.
    /// It's used to verify if drips configuration is the previously set one.
    /// @param receivers The list of the drips receivers.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// If the drips have never been updated, pass an empty array.
    /// @return dripsConfigurationHash The hash of the drips configuration
    function hashDrips(DripsReceiver[] memory receivers)
        public
        pure
        returns (bytes32 dripsConfigurationHash)
    {
        return Drips.hashDrips(receivers);
    }

    /// @notice Sets user splits configuration.
    /// @param userId The user ID
    /// @param receivers The list of the user's splits receivers to be set.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the user.
    function setSplits(uint256 userId, SplitsReceiver[] memory receivers)
        public
        whenNotPaused
        onlyApp(userId)
    {
        Splits.setSplits(_dripsHubStorage().splits, userId, receivers);
    }

    /// @notice Current user's splits hash, see `hashSplits`.
    /// @param userId The user ID
    /// @return currSplitsHash The current user's splits hash
    function splitsHash(uint256 userId) public view returns (bytes32 currSplitsHash) {
        return Splits.splitsHash(_dripsHubStorage().splits, userId);
    }

    /// @notice Calculates the hash of the list of splits receivers.
    /// @param receivers The list of the splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// @return receiversHash The hash of the list of splits receivers.
    function hashSplits(SplitsReceiver[] memory receivers)
        public
        pure
        returns (bytes32 receiversHash)
    {
        return Splits.hashSplits(receivers);
    }

    /// @notice Returns the DripsHub storage.
    /// @return storageRef The storage.
    function _dripsHubStorage() internal view returns (DripsHubStorage storage storageRef) {
        bytes32 slot = storageSlot;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Based on OpenZeppelin's StorageSlot
            storageRef.slot := slot
        }
    }

    /// @notice Generates an asset ID for the ERC-20 token
    /// @param erc20 The ERC-20 token
    /// @return assetId The asset ID
    function _assetId(IERC20 erc20) internal pure returns (uint256 assetId) {
        return uint160(address(erc20));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

/// @notice A drips receiver
struct DripsReceiver {
    /// @notice The user ID.
    uint256 userId;
    /// @notice The drips configuration.
    DripsConfig config;
}

/// @notice Describes a drips configuration.
/// It's constructed from `amtPerSec`, `start` and `duration` as
/// `amtPerSec << 64 | start << 32 | duration`.
/// `amtPerSec` is the amount per second being dripped. Must never be zero.
/// `start` is the timestamp when dripping should start.
/// If zero, use the timestamp when drips are configured.
/// `duration` is the duration of dripping.
/// If zero, drip until balance runs out.
type DripsConfig is uint192;

using DripsConfigImpl for DripsConfig global;

library DripsConfigImpl {
    /// @notice Create a new DripsConfig.
    /// @param _amtPerSec The amount per second being dripped. Must never be zero.
    /// @param _start The timestamp when dripping should start.
    /// If zero, use the timestamp when drips are configured.
    /// @param _duration The duration of dripping.
    /// If zero, drip until balance runs out.
    function create(
        uint128 _amtPerSec,
        uint32 _start,
        uint32 _duration
    ) internal pure returns (DripsConfig) {
        uint192 config = _amtPerSec;
        config = (config << 32) | _start;
        config = (config << 32) | _duration;
        return DripsConfig.wrap(config);
    }

    /// @notice Extracts amtPerSec from a `DripsConfig`
    function amtPerSec(DripsConfig config) internal pure returns (uint128) {
        return uint128(DripsConfig.unwrap(config) >> 64);
    }

    /// @notice Extracts start from a `DripsConfig`
    function start(DripsConfig config) internal pure returns (uint32) {
        return uint32(DripsConfig.unwrap(config) >> 32);
    }

    /// @notice Extracts duration from a `DripsConfig`
    function duration(DripsConfig config) internal pure returns (uint32) {
        return uint32(DripsConfig.unwrap(config));
    }

    /// @notice Compares two `DripsConfig`s.
    /// First compares their `amtPerSec`s, then their `start`s and then their `duration`s.
    function lt(DripsConfig config, DripsConfig otherConfig) internal pure returns (bool) {
        return DripsConfig.unwrap(config) < DripsConfig.unwrap(otherConfig);
    }
}

library Drips {
    /// @notice Maximum number of drips receivers of a single user.
    /// Limits cost of changes in drips configuration.
    uint8 internal constant MAX_DRIPS_RECEIVERS = 100;

    /// @notice Emitted when the drips configuration of a user is updated.
    /// @param userId The user ID.
    /// @param assetId The used asset ID
    /// @param receiversHash The drips receivers list hash
    /// @param balance The new drips balance. These funds will be dripped to the receivers.
    event DripsSet(
        uint256 indexed userId,
        uint256 indexed assetId,
        bytes32 indexed receiversHash,
        uint128 balance
    );

    /// @notice Emitted when a user is seen in a drips receivers list.
    /// @param receiversHash The drips receivers list hash
    /// @param userId The user ID.
    /// @param config The drips configuration.
    event DripsReceiverSeen(
        bytes32 indexed receiversHash,
        uint256 indexed userId,
        DripsConfig config
    );

    /// @notice Emitted when drips are received and are ready to be split.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param amt The received amount.
    /// @param receivableCycles The number of cycles which still can be received.
    event ReceivedDrips(
        uint256 indexed userId,
        uint256 indexed assetId,
        uint128 amt,
        uint32 receivableCycles
    );

    struct Storage {
        /// @notice User drips states.
        /// The keys are the asset ID and the user ID.
        mapping(uint256 => mapping(uint256 => DripsState)) dripsStates;
    }

    struct DripsState {
        /// @notice Drips receivers list hash, see `hashDrips`.
        bytes32 dripsHash;
        /// @notice The next cycle to be received
        uint32 nextReceivableCycle;
        /// @notice The time when drips have been configured for the last time
        uint32 updateTime;
        /// @notice The end time of drips without duration
        uint32 defaultEnd;
        /// @notice The balance when drips have been configured for the last time
        uint128 balance;
        /// @notice The changes of received amounts on specific cycle.
        /// The keys are cycles, each cycle `C` becomes receivable on timestamp `C * cycleSecs`.
        /// Values for cycles before `nextReceivableCycle` are guaranteed to be zeroed.
        /// This means that the value of `amtDeltas[nextReceivableCycle].thisCycle` is always
        /// relative to 0 or in other words it's an absolute value independent from other cycles.
        mapping(uint32 => AmtDelta) amtDeltas;
    }

    struct AmtDelta {
        /// @notice Amount delta applied on this cycle
        int128 thisCycle;
        /// @notice Amount delta applied on the next cycle
        int128 nextCycle;
    }

    /// @notice Counts cycles from which drips can be received.
    /// This function can be used to detect that there are
    /// too many cycles to analyze in a single transaction.
    /// @param s The drips storage
    /// @param cycleSecs The cycle length in seconds.
    /// Must be the same in all calls working on a single storage instance. Must be higher than 1.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @return cycles The number of cycles which can be flushed
    function receivableDripsCycles(
        Storage storage s,
        uint32 cycleSecs,
        uint256 userId,
        uint256 assetId
    ) internal view returns (uint32 cycles) {
        uint32 nextReceivableCycle = s.dripsStates[assetId][userId].nextReceivableCycle;
        // The currently running cycle is not receivable yet
        uint32 currCycle = _cycleOf(_currTimestamp(), cycleSecs);
        if (nextReceivableCycle == 0 || nextReceivableCycle > currCycle) return 0;
        return currCycle - nextReceivableCycle;
    }

    /// @notice Calculate effects of calling `receiveDrips` with the given parameters.
    /// @param s The drips storage
    /// @param cycleSecs The cycle length in seconds.
    /// Must be the same in all calls working on a single storage instance. Must be higher than 1.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param maxCycles The maximum number of received drips cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivableAmt The amount which would be received
    /// @return receivableCycles The number of cycles which would still be receivable after the call
    function receivableDrips(
        Storage storage s,
        uint32 cycleSecs,
        uint256 userId,
        uint256 assetId,
        uint32 maxCycles
    ) internal view returns (uint128 receivableAmt, uint32 receivableCycles) {
        uint32 allReceivableCycles = receivableDripsCycles(s, cycleSecs, userId, assetId);
        uint32 receivedCycles = maxCycles < allReceivableCycles ? maxCycles : allReceivableCycles;
        receivableCycles = allReceivableCycles - receivedCycles;
        DripsState storage state = s.dripsStates[assetId][userId];
        uint32 receivedCycle = state.nextReceivableCycle;
        int128 cycleAmt = 0;
        for (uint256 i = 0; i < receivedCycles; i++) {
            cycleAmt += state.amtDeltas[receivedCycle].thisCycle;
            receivableAmt += uint128(cycleAmt);
            cycleAmt += state.amtDeltas[receivedCycle].nextCycle;
            receivedCycle++;
        }
    }

    /// @notice Receive drips from unreceived cycles of the user.
    /// Received drips cycles won't need to be analyzed ever again.
    /// Calling this function does not receive but makes the funds ready to be split and received.
    /// @param s The drips storage
    /// @param cycleSecs The cycle length in seconds.
    /// Must be the same in all calls working on a single storage instance. Must be higher than 1.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param maxCycles The maximum number of received drips cycles.
    /// If too low, receiving will be cheap, but may not cover many cycles.
    /// If too high, receiving may become too expensive to fit in a single transaction.
    /// @return receivedAmt The received amount
    /// @return receivableCycles The number of cycles which still can be received
    function receiveDrips(
        Storage storage s,
        uint32 cycleSecs,
        uint256 userId,
        uint256 assetId,
        uint32 maxCycles
    ) internal returns (uint128 receivedAmt, uint32 receivableCycles) {
        receivableCycles = receivableDripsCycles(s, cycleSecs, userId, assetId);
        uint32 cycles = maxCycles < receivableCycles ? maxCycles : receivableCycles;
        receivableCycles -= cycles;
        if (cycles > 0) {
            DripsState storage state = s.dripsStates[assetId][userId];
            uint32 cycle = state.nextReceivableCycle;
            int128 cycleAmt = 0;
            for (uint256 i = 0; i < cycles; i++) {
                cycleAmt += state.amtDeltas[cycle].thisCycle;
                receivedAmt += uint128(cycleAmt);
                cycleAmt += state.amtDeltas[cycle].nextCycle;
                delete state.amtDeltas[cycle];
                cycle++;
            }
            // The next cycle delta must be relative to the last received cycle, which got zeroed.
            // In other words the next cycle delta must be an absolute value.
            if (cycleAmt != 0) state.amtDeltas[cycle].thisCycle += cycleAmt;
            state.nextReceivableCycle = cycle;
        }
        emit ReceivedDrips(userId, assetId, receivedAmt, receivableCycles);
    }

    /// @notice Current user drips state.
    /// @param s The drips storage
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @return dripsHash The current drips receivers list hash, see `hashDrips`
    /// @return updateTime The time when drips have been configured for the last time
    /// @return balance The balance when drips have been configured for the last time
    function dripsState(
        Storage storage s,
        uint256 userId,
        uint256 assetId
    )
        internal
        view
        returns (
            bytes32 dripsHash,
            uint32 updateTime,
            uint128 balance,
            uint32 defaultEnd
        )
    {
        DripsState storage state = s.dripsStates[assetId][userId];
        return (state.dripsHash, state.updateTime, state.balance, state.defaultEnd);
    }

    /// @notice User drips balance at a given timestamp
    /// @param s The drips storage
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param receivers The current drips receivers list
    /// @param timestamp The timestamps for which balance should be calculated.
    /// It can't be lower than the timestamp of the last call to `setDrips`.
    /// If it's bigger than `block.timestamp`, then it's a prediction assuming
    /// that `setDrips` won't be called before `timestamp`.
    /// @return balance The user balance on `timestamp`
    function balanceAt(
        Storage storage s,
        uint256 userId,
        uint256 assetId,
        DripsReceiver[] memory receivers,
        uint32 timestamp
    ) internal view returns (uint128 balance) {
        DripsState storage state = s.dripsStates[assetId][userId];
        require(timestamp >= state.updateTime, "Timestamp before last drips update");
        require(hashDrips(receivers) == state.dripsHash, "Invalid current drips list");
        return _balanceAt(state.balance, state.updateTime, state.defaultEnd, receivers, timestamp);
    }

    /// @notice Sets the user's drips configuration.
    /// @param s The drips storage
    /// @param cycleSecs The cycle length in seconds.
    /// Must be the same in all calls working on a single storage instance. Must be higher than 1.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The drips balance change being applied.
    /// Positive when adding funds to the drips balance, negative to removing them.
    /// @param newReceivers The list of the drips receivers of the user to be set.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// @return newBalance The new drips balance of the user.
    /// @return realBalanceDelta The actually applied drips balance change.
    function setDrips(
        Storage storage s,
        uint32 cycleSecs,
        uint256 userId,
        uint256 assetId,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers
    ) internal returns (uint128 newBalance, int128 realBalanceDelta) {
        DripsState storage state = s.dripsStates[assetId][userId];
        bytes32 currDripsHash = hashDrips(currReceivers);
        require(currDripsHash == state.dripsHash, "Invalid current drips list");
        uint32 lastUpdate = state.updateTime;
        uint32 currDefaultEnd = state.defaultEnd;
        uint128 lastBalance = state.balance;
        {
            uint128 currBalance = _balanceAt(
                lastBalance,
                lastUpdate,
                currDefaultEnd,
                currReceivers,
                _currTimestamp()
            );
            int136 balance = int128(currBalance) + int136(balanceDelta);
            if (balance < 0) balance = 0;
            newBalance = uint128(uint136(balance));
            realBalanceDelta = int128(balance - int128(currBalance));
        }
        uint32 newDefaultEnd = calcDefaultEnd(newBalance, newReceivers);
        _updateReceiverStates(
            s.dripsStates[assetId],
            cycleSecs,
            currReceivers,
            lastUpdate,
            currDefaultEnd,
            newReceivers,
            newDefaultEnd
        );
        state.updateTime = _currTimestamp();
        state.defaultEnd = newDefaultEnd;
        state.balance = newBalance;
        bytes32 newDripsHash = hashDrips(newReceivers);
        emit DripsSet(userId, assetId, newDripsHash, newBalance);
        if (newDripsHash != currDripsHash) {
            state.dripsHash = newDripsHash;
            for (uint256 i = 0; i < newReceivers.length; i++) {
                DripsReceiver memory receiver = newReceivers[i];
                emit DripsReceiverSeen(newDripsHash, receiver.userId, receiver.config);
            }
        }
    }

    function _addDefaultEnd(
        uint256[] memory defaultEnds,
        uint256 idx,
        uint192 amtPerSec,
        uint32 start
    ) private pure {
        defaultEnds[idx] = (uint256(amtPerSec) << 32) | start;
    }

    function _getDefaultEnd(uint256[] memory defaultEnds, uint256 idx)
        private
        pure
        returns (uint256 amtPerSec, uint256 start)
    {
        uint256 val;
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            val := mload(add(32, add(defaultEnds, shl(5, idx))))
        }
        return (val >> 32, uint32(val));
    }

    /// @notice Calculates the end time of drips without duration.
    /// @param balance The balance when drips have started
    /// @param receivers The list of drips receivers.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// @return defaultEndTime The end time of drips without duration.
    function calcDefaultEnd(uint128 balance, DripsReceiver[] memory receivers)
        internal
        view
        returns (uint32 defaultEndTime)
    {
        require(receivers.length <= MAX_DRIPS_RECEIVERS, "Too many drips receivers");
        uint256[] memory defaultEnds = new uint256[](receivers.length);
        uint256 defaultEndsLen = 0;
        uint168 spent = 0;
        for (uint256 i = 0; i < receivers.length; i++) {
            DripsReceiver memory receiver = receivers[i];
            uint128 amtPerSec = receiver.config.amtPerSec();
            require(amtPerSec != 0, "Drips receiver amtPerSec is zero");
            if (i > 0) require(_isOrdered(receivers[i - 1], receiver), "Receivers not sorted");
            // Default drips end doesn't matter here, the end time is ignored when
            // the duration is zero and if it's non-zero the default end is not used anyway
            (uint32 start, uint32 end) = _dripsRangeInFuture(receiver, _currTimestamp(), 0);
            if (receiver.config.duration() == 0) {
                _addDefaultEnd(defaultEnds, defaultEndsLen++, amtPerSec, start);
            } else {
                spent += uint160(end - start) * amtPerSec;
            }
        }
        require(balance >= spent, "Insufficient balance");
        balance -= uint128(spent);
        return _calcDefaultEnd(defaultEnds, defaultEndsLen, balance);
    }

    /// @notice Calculates the end time of drips without duration.
    /// @param defaultEnds The list of default ends
    /// @param balance The balance when drips have started
    /// @return defaultEnd The end time of drips without duration.
    function _calcDefaultEnd(
        uint256[] memory defaultEnds,
        uint256 defaultEndsLen,
        uint128 balance
    ) private view returns (uint32 defaultEnd) {
        unchecked {
            uint32 minEnd = _currTimestamp();
            uint32 maxEnd = type(uint32).max;
            if (defaultEndsLen == 0 || balance == 0) return minEnd;
            if (_isBalanceEnough(defaultEnds, defaultEndsLen, balance, maxEnd)) return maxEnd;
            uint256 enoughEnd = minEnd;
            uint256 notEnoughEnd = maxEnd;
            while (true) {
                uint256 end = (enoughEnd + notEnoughEnd) / 2;
                if (end == enoughEnd) return uint32(end);
                if (_isBalanceEnough(defaultEnds, defaultEndsLen, balance, end)) {
                    enoughEnd = end;
                } else {
                    notEnoughEnd = end;
                }
            }
        }
    }

    /// @notice Check if a given balance is enough to cover default drips until the given time.
    /// @param defaultEnds The list of default ends
    /// @param defaultEndsLen The length of `defaultEnds`
    /// @param balance The balance when drips have started
    /// @param end The time until which the drips are checked to be covered
    /// @return isEnough `true` if the balance is enough, `false` otherwise
    function _isBalanceEnough(
        uint256[] memory defaultEnds,
        uint256 defaultEndsLen,
        uint256 balance,
        uint256 end
    ) private pure returns (bool isEnough) {
        unchecked {
            uint256 spent = 0;
            for (uint256 i = 0; i < defaultEndsLen; i++) {
                (uint256 amtPerSec, uint256 start) = _getDefaultEnd(defaultEnds, i);
                if (end <= start) continue;
                spent += amtPerSec * (end - start);
                if (spent > balance) return false;
            }
            return true;
        }
    }

    /// @notice Calculates the drips balance at a given timestamp.
    /// @param lastBalance The balance when drips have started
    /// @param lastUpdate The timestamp when drips have started.
    /// @param defaultEnd The end time of drips without duration
    /// @param receivers The list of drips receivers.
    /// @param timestamp The timestamps for which balance should be calculated.
    /// It can't be lower than `lastUpdate`.
    /// If it's bigger than `block.timestamp`, then it's a prediction assuming
    /// that `setDrips` won't be called before `timestamp`.
    /// @return balance The user balance on `timestamp`
    function _balanceAt(
        uint128 lastBalance,
        uint32 lastUpdate,
        uint32 defaultEnd,
        DripsReceiver[] memory receivers,
        uint32 timestamp
    ) private pure returns (uint128 balance) {
        balance = lastBalance;
        for (uint256 i = 0; i < receivers.length; i++) {
            DripsReceiver memory receiver = receivers[i];
            (uint32 start, uint32 end) = _dripsRange({
                receiver: receiver,
                updateTime: lastUpdate,
                defaultEnd: defaultEnd,
                startCap: lastUpdate,
                endCap: timestamp
            });
            balance -= (end - start) * receiver.config.amtPerSec();
        }
    }

    /// @notice Calculates the hash of the drips configuration.
    /// It's used to verify if drips configuration is the previously set one.
    /// @param receivers The list of the drips receivers.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// If the drips have never been updated, pass an empty array.
    /// @return dripsConfigurationHash The hash of the drips configuration
    function hashDrips(DripsReceiver[] memory receivers)
        internal
        pure
        returns (bytes32 dripsConfigurationHash)
    {
        if (receivers.length == 0) return bytes32(0);
        return keccak256(abi.encode(receivers));
    }

    /// @notice Applies the effects of the change of the drips on the receivers' drips states.
    /// @param states The drips states for a single asset, the key is the user ID
    /// @param cycleSecs_ The cycle length in seconds.
    /// Must be the same in all calls working on a single storage instance. Must be higher than 1.
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user.
    /// If this is the first update, pass an empty array.
    /// @param lastUpdate the last time the sender updated the drips.
    /// If this is the first update, pass zero.
    /// @param currDefaultEnd Time when drips without duration
    /// were supposed to end according to the last drips update.
    /// @param newReceivers  The list of the drips receivers of the user to be set.
    /// Must be sorted, deduplicated and without 0 amtPerSecs.
    /// @param newDefaultEnd Time when drips without duration
    /// will end according to the new drips configuration.
    function _updateReceiverStates(
        mapping(uint256 => DripsState) storage states,
        uint32 cycleSecs_,
        DripsReceiver[] memory currReceivers,
        uint32 lastUpdate,
        uint32 currDefaultEnd,
        DripsReceiver[] memory newReceivers,
        uint32 newDefaultEnd
    ) private {
        // A copy shallow in the stack, prevents "stack too deep" errors
        uint32 cycleSecs = cycleSecs_;
        uint256 currIdx = 0;
        uint256 newIdx = 0;
        while (true) {
            bool pickCurr = currIdx < currReceivers.length;
            DripsReceiver memory currRecv;
            if (pickCurr) currRecv = currReceivers[currIdx];

            bool pickNew = newIdx < newReceivers.length;
            DripsReceiver memory newRecv;
            if (pickNew) newRecv = newReceivers[newIdx];

            // Limit picking both curr and new to situations when they differ only by time
            if (
                pickCurr &&
                pickNew &&
                (currRecv.userId != newRecv.userId ||
                    currRecv.config.amtPerSec() != newRecv.config.amtPerSec())
            ) {
                pickCurr = _isOrdered(currRecv, newRecv);
                pickNew = !pickCurr;
            }

            if (pickCurr && pickNew) {
                // Shift the existing drip to fulfil the new configuration
                DripsState storage state = states[currRecv.userId];
                (uint32 currStart, uint32 currEnd) = _dripsRangeInFuture(
                    currRecv,
                    lastUpdate,
                    currDefaultEnd
                );
                (uint32 newStart, uint32 newEnd) = _dripsRangeInFuture(
                    newRecv,
                    _currTimestamp(),
                    newDefaultEnd
                );
                {
                    int256 amtPerSec = int256(uint256(currRecv.config.amtPerSec()));
                    // Move the start and end times if updated
                    _addDeltaRange(state, cycleSecs, currStart, newStart, -amtPerSec);
                    _addDeltaRange(state, cycleSecs, currEnd, newEnd, amtPerSec);
                }
                // Ensure that the user receives the updated cycles
                uint32 currStartCycle = _cycleOf(currStart, cycleSecs);
                uint32 newStartCycle = _cycleOf(newStart, cycleSecs);
                if (currStartCycle > newStartCycle && state.nextReceivableCycle > newStartCycle) {
                    state.nextReceivableCycle = newStartCycle;
                }
            } else if (pickCurr) {
                // Remove an existing drip
                DripsState storage state = states[currRecv.userId];
                (uint32 start, uint32 end) = _dripsRangeInFuture(
                    currRecv,
                    lastUpdate,
                    currDefaultEnd
                );
                int256 amtPerSec = int256(uint256(currRecv.config.amtPerSec()));
                _addDeltaRange(state, cycleSecs, start, end, -amtPerSec);
            } else if (pickNew) {
                // Create a new drip
                DripsState storage state = states[newRecv.userId];
                (uint32 start, uint32 end) = _dripsRangeInFuture(
                    newRecv,
                    _currTimestamp(),
                    newDefaultEnd
                );
                int256 amtPerSec = int256(uint256(newRecv.config.amtPerSec()));
                _addDeltaRange(state, cycleSecs, start, end, amtPerSec);
                // Ensure that the user receives the updated cycles
                uint32 startCycle = _cycleOf(start, cycleSecs);
                if (state.nextReceivableCycle == 0 || state.nextReceivableCycle > startCycle) {
                    state.nextReceivableCycle = startCycle;
                }
            } else {
                break;
            }

            if (pickCurr) currIdx++;
            if (pickNew) newIdx++;
        }
    }

    /// @notice Calculates the time range in the future in which a receiver will be dripped to.
    /// @param receiver The drips receiver
    /// @param defaultEnd The end time of drips without duration
    function _dripsRangeInFuture(
        DripsReceiver memory receiver,
        uint32 updateTime,
        uint32 defaultEnd
    ) private view returns (uint32 start, uint32 end) {
        return _dripsRange(receiver, updateTime, defaultEnd, _currTimestamp(), type(uint32).max);
    }

    /// @notice Calculates the time range in which a receiver is to be dripped to.
    /// This range is capped to provide a view on drips through a specific time window.
    /// @param receiver The drips receiver
    /// @param updateTime The time when drips are configured
    /// @param defaultEnd The end time of drips without duration
    /// @param startCap The timestamp the drips range start should be capped to
    /// @param endCap The timestamp the drips range end should be capped to
    function _dripsRange(
        DripsReceiver memory receiver,
        uint32 updateTime,
        uint32 defaultEnd,
        uint32 startCap,
        uint32 endCap
    ) private pure returns (uint32 start, uint32 end_) {
        start = receiver.config.start();
        if (start == 0) start = updateTime;
        uint40 end = uint40(start) + receiver.config.duration();
        if (end == start) end = defaultEnd;
        if (start < startCap) start = startCap;
        if (end > endCap) end = endCap;
        if (end < start) end = start;
        return (start, uint32(end));
    }

    /// @notice Adds funds received by a user in a given time range
    /// @param state The user state
    /// @param cycleSecs The cycle length in seconds.
    /// Must be the same in all calls working on a single storage instance. Must be higher than 1.
    /// @param start The timestamp from which the delta takes effect
    /// @param end The timestamp until which the delta takes effect
    /// @param amtPerSec The dripping rate
    function _addDeltaRange(
        DripsState storage state,
        uint32 cycleSecs,
        uint32 start,
        uint32 end,
        int256 amtPerSec
    ) private {
        if (start == end) return;
        mapping(uint32 => AmtDelta) storage amtDeltas = state.amtDeltas;
        _addDelta(amtDeltas, cycleSecs, start, amtPerSec);
        _addDelta(amtDeltas, cycleSecs, end, -amtPerSec);
    }

    /// @notice Adds delta of funds received by a user at a given time
    /// @param amtDeltas The user amount deltas
    /// @param cycleSecs The cycle length in seconds.
    /// Must be the same in all calls working on a single storage instance. Must be higher than 1.
    /// @param timestamp The timestamp when the deltas need to be added
    /// @param amtPerSec The dripping rate
    function _addDelta(
        mapping(uint32 => AmtDelta) storage amtDeltas,
        uint32 cycleSecs,
        uint32 timestamp,
        int256 amtPerSec
    ) private {
        unchecked {
            AmtDelta storage amtDelta = amtDeltas[_cycleOf(timestamp, cycleSecs)];
            int256 thisCycleDelta = amtDelta.thisCycle;
            int256 nextCycleDelta = amtDelta.nextCycle;

            // In order to set a delta on a specific timestamp it must be introduced in two cycles.
            // The cycle delta is split proportionally based on how much this cycle is affected.
            // The next cycle has the rest of the delta applied, so the update is fully completed.
            uint32 nextCycleSecs = timestamp % cycleSecs;
            uint32 thisCycleSecs = cycleSecs - nextCycleSecs;
            thisCycleDelta += int256(uint256(thisCycleSecs)) * amtPerSec;
            nextCycleDelta += int256(uint256(nextCycleSecs)) * amtPerSec;
            require(
                int128(thisCycleDelta) == thisCycleDelta &&
                    int128(nextCycleDelta) == nextCycleDelta,
                "AmtDelta underflow or overflow"
            );

            amtDelta.thisCycle = int128(thisCycleDelta);
            amtDelta.nextCycle = int128(nextCycleDelta);
        }
    }

    /// @notice Checks if two receivers fulfil the sortedness requirement of the receivers list.
    /// @param prev The previous receiver
    /// @param prev The next receiver
    function _isOrdered(DripsReceiver memory prev, DripsReceiver memory next)
        private
        pure
        returns (bool)
    {
        if (prev.userId != next.userId) return prev.userId < next.userId;
        return prev.config.lt(next.config);
    }

    /// @notice Calculates the cycle containing the given timestamp.
    /// @param timestamp The timestamp.
    /// @param cycleSecs The cycle length in seconds.
    /// @return cycle The cycle containing the timestamp.
    function _cycleOf(uint32 timestamp, uint32 cycleSecs) private pure returns (uint32 cycle) {
        unchecked {
            return timestamp / cycleSecs + 1;
        }
    }

    /// @notice The current timestamp, casted to the library's internal representation.
    /// @return timestamp The current timestamp
    function _currTimestamp() private view returns (uint32 timestamp) {
        return uint32(block.timestamp);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice The reserve interface as seen by the users.
interface IReserve {
    /// @notice Deposits funds into the reserve.
    /// The reserve will `transferFrom` `amt` tokens from the `from` address.
    /// @param token The used token.
    /// @param from The address from which funds are deposited.
    /// @param amt The deposited amount.
    function deposit(
        IERC20 token,
        address from,
        uint256 amt
    ) external;

    /// @notice Withdraws funds from the reserve.
    /// The reserve will transfer `amt` tokens to the `to` address.
    /// Only funds previously deposited can be withdrawn.
    /// @param token The used token.
    /// @param to The address to which funds are withdrawn.
    /// @param amt The withdrawn amount.
    function withdraw(
        IERC20 token,
        address to,
        uint256 amt
    ) external;
}

/// @notice The reserve plugin interface required by the reserve.
interface IReservePlugin {
    /// @notice Called by the reserve when it starts using the plugin,
    /// immediately after transferring to the plugin all the deposited funds.
    /// This initial transfer won't trigger the regular call to `afterDeposition`.
    /// @param token The used token.
    /// @param amt The amount which has been transferred for deposition.
    function afterStart(IERC20 token, uint256 amt) external;

    /// @notice Called by the reserve immediately after
    /// transferring funds to the plugin for deposition.
    /// @param token The used token.
    /// @param amt The amount which has been transferred for deposition.
    function afterDeposition(IERC20 token, uint256 amt) external;

    /// @notice Called by the reserve right before transferring funds for withdrawal.
    /// The reserve will `transferFrom` the tokens from the plugin address.
    /// The reserve can always withdraw everything that has been ever deposited, but never more.
    /// @param token The used token.
    /// @param amt The amount which will be transferred.
    function beforeWithdrawal(IERC20 token, uint256 amt) external;

    /// @notice Called by the reserve when it stops using the plugin,
    /// right before transferring from the plugin all the deposited funds.
    /// The reserve will `transferFrom` the tokens from the plugin address.
    /// This final transfer won't trigger the regular call to `beforeWithdrawal`.
    /// @param token The used token.
    /// @param amt The amount which will be transferred.
    function beforeEnd(IERC20 token, uint256 amt) external;
}

/// @notice The ERC-20 tokens reserve contract.
/// The registered users can deposit and withdraw funds.
/// The reserve by default doesn't do anything with the tokens,
/// but for each ERC-20 address a plugin can be registered for tokens storage.
contract Reserve is IReserve, Ownable {
    using SafeERC20 for IERC20;
    /// @notice The dummy plugin address meaning that no plugin is being used.
    IReservePlugin public constant NO_PLUGIN = IReservePlugin(address(0));

    /// @notice A set of addresses considered users.
    /// The value is `true` if an address is a user, `false` otherwise.
    mapping(address => bool) public isUser;
    /// @notice How many tokens are deposited for each token address.
    mapping(IERC20 => uint256) public deposited;
    /// @notice The reserved plugins for each token address.
    mapping(IERC20 => IReservePlugin) public plugins;

    /// @notice Emitted when a plugin is set.
    /// @param owner The address which called the function.
    /// @param token The token for which plugin has been set.
    /// @param oldPlugin The old plugin address. `NO_PLUGIN` if no plugin was being used.
    /// @param newPlugin The new plugin address. `NO_PLUGIN` if no plugin will be used.
    /// @param amt The amount which has been withdrawn
    /// from the old plugin and deposited into the new one.
    event PluginSet(
        address owner,
        IERC20 indexed token,
        IReservePlugin indexed oldPlugin,
        IReservePlugin indexed newPlugin,
        uint256 amt
    );

    /// @notice Emitted when funds are deposited.
    /// @param user The address which called the function.
    /// @param token The used token.
    /// @param from The address from which tokens have been transferred.
    /// @param amt The amount which has been deposited.
    event Deposited(address user, IERC20 indexed token, address indexed from, uint256 amt);

    /// @notice Emitted when funds are withdrawn.
    /// @param user The address which called the function.
    /// @param token The used token.
    /// @param to The address to which tokens have been transferred.
    /// @param amt The amount which has been withdrawn.
    event Withdrawn(address user, IERC20 indexed token, address indexed to, uint256 amt);

    /// @notice Emitted when funds are force withdrawn.
    /// @param owner The address which called the function.
    /// @param token The used token.
    /// @param plugin The address of the plugin from which funds have been withdrawn or
    /// `NO_PLUGIN` if from the reserve itself.
    /// @param to The address to which tokens have been transferred.
    /// @param amt The amount which has been withdrawn.
    event ForceWithdrawn(
        address owner,
        IERC20 indexed token,
        IReservePlugin indexed plugin,
        address indexed to,
        uint256 amt
    );

    /// @notice Emitted when an address is registered as a user.
    /// @param owner The address which called the function.
    /// @param user The registered user address.
    event UserAdded(address owner, address indexed user);

    /// @notice Emitted when an address is unregistered as a user.
    /// @param owner The address which called the function.
    /// @param user The unregistered user address.
    event UserRemoved(address owner, address indexed user);

    /// @param owner The initial owner address.
    constructor(address owner) {
        transferOwnership(owner);
    }

    modifier onlyUser() {
        require(isUser[msg.sender], "Reserve: caller is not the user");
        _;
    }

    /// @notice Sets a plugin for a given token.
    /// All future deposits and withdrawals of that token will be made using that plugin.
    /// All currently deposited tokens of that type will be withdrawn from the plugin previously
    /// set for that token and deposited into the new one.
    /// If no plugin has been set, funds are deposited from the reserve itself.
    /// If no plugin is being set, funds are deposited into the reserve itself.
    /// Callable only by the current owner.
    /// @param token The used token.
    /// @param newPlugin The new plugin address. `NO_PLUGIN` if no plugin should be used.
    function setPlugin(IERC20 token, IReservePlugin newPlugin) public onlyOwner {
        IReservePlugin oldPlugin = plugins[token];
        plugins[token] = newPlugin;
        uint256 amt = deposited[token];
        if (oldPlugin != NO_PLUGIN) oldPlugin.beforeEnd(token, amt);
        _transfer(token, _pluginAddr(oldPlugin), _pluginAddr(newPlugin), amt);
        if (newPlugin != NO_PLUGIN) newPlugin.afterStart(token, amt);
        emit PluginSet(msg.sender, token, oldPlugin, newPlugin, amt);
    }

    /// @notice Deposits funds into the reserve.
    /// The reserve will `transferFrom` `amt` tokens from the `from` address.
    /// Callable only by a current user.
    /// @param token The used token.
    /// @param from The address from which funds are deposited.
    /// @param amt The deposited amount.
    function deposit(
        IERC20 token,
        address from,
        uint256 amt
    ) public override onlyUser {
        IReservePlugin plugin = plugins[token];
        require(from != address(plugin) && from != address(this), "Reserve: deposition from self");
        deposited[token] += amt;
        _transfer(token, from, _pluginAddr(plugin), amt);
        if (plugin != NO_PLUGIN) plugin.afterDeposition(token, amt);
        emit Deposited(msg.sender, token, from, amt);
    }

    /// @notice Withdraws funds from the reserve.
    /// The reserve will transfer `amt` tokens to the `to` address.
    /// Only funds previously deposited can be withdrawn.
    /// Callable only by a current user.
    /// @param token The used token.
    /// @param to The address to which funds are withdrawn.
    /// @param amt The withdrawn amount.
    function withdraw(
        IERC20 token,
        address to,
        uint256 amt
    ) public override onlyUser {
        uint256 balance = deposited[token];
        require(balance >= amt, "Reserve: withdrawal over balance");
        deposited[token] = balance - amt;
        IReservePlugin plugin = plugins[token];
        if (plugin != NO_PLUGIN) plugin.beforeWithdrawal(token, amt);
        _transfer(token, _pluginAddr(plugin), to, amt);
        emit Withdrawn(msg.sender, token, to, amt);
    }

    /// @notice Withdraws funds from the reserve or a plugin.
    /// The reserve will transfer `amt` tokens to the `to` address.
    /// The function doesn't update the deposited amount counter.
    /// If used recklessly, it may cause a mismatch between the counter and the actual balance
    /// making valid future calls to `withdraw` or `setPlugin` fail due to lack of funds.
    /// Callable only by the current owner.
    /// @param token The used token.
    /// @param plugin The plugin to withdraw from.
    /// It doesn't need to be registered as a plugin for `token`.
    /// Pass `NO_PLUGIN` to withdraw directly from the reserve balance.
    /// @param to The address to which funds are withdrawn.
    /// @param amt The withdrawn amount.
    function forceWithdraw(
        IERC20 token,
        IReservePlugin plugin,
        address to,
        uint256 amt
    ) public onlyOwner {
        if (plugin != NO_PLUGIN) plugin.beforeWithdrawal(token, amt);
        _transfer(token, _pluginAddr(plugin), to, amt);
        emit ForceWithdrawn(msg.sender, token, plugin, to, amt);
    }

    /// @notice Sets the deposited amount counter for a token without transferring any funds.
    /// If used recklessly, it may cause a mismatch between the counter and the actual balance
    /// making valid future calls to `withdraw` or `setPlugin` fail due to lack of funds.
    /// It may also make the counter lower than what users expect it to be again making
    /// valid future calls to `withdraw` fail.
    /// Callable only by the current owner.
    /// @param token The used token.
    /// @param amt The new deposited amount counter value.
    function setDeposited(IERC20 token, uint256 amt) public onlyOwner {
        deposited[token] = amt;
    }

    /// @notice Adds a new user.
    /// @param user The new user address.
    function addUser(address user) public onlyOwner {
        isUser[user] = true;
        emit UserAdded(msg.sender, user);
    }

    /// @notice Removes an existing user.
    /// @param user The removed user address.
    function removeUser(address user) public onlyOwner {
        isUser[user] = false;
        emit UserRemoved(msg.sender, user);
    }

    function _pluginAddr(IReservePlugin plugin) internal view returns (address) {
        return plugin == NO_PLUGIN ? address(this) : address(plugin);
    }

    function _transfer(
        IERC20 token,
        address from,
        address to,
        uint256 amt
    ) internal {
        if (from == address(this)) token.safeTransfer(to, amt);
        else token.safeTransferFrom(from, to, amt);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {StorageSlot} from "openzeppelin-contracts/utils/StorageSlot.sol";

/// @notice A mix-in for contract UUPS-upgradability, pausability and admin management.
/// It can't be used directly, only via a proxy. It uses the upgrade-safe ERC-1967 storage scheme.
///
/// Managed uses the ERC-1967 admin slot to store the admin address.
/// All instances of the contracts are owned by address `0x00`.
/// While this contract is capable of updating the admin,
/// the proxy is expected to set up the initial value of the ERC-1967 admin.
///
/// All instances of the contracts are paused and can't be unpaused.
/// When a proxy uses such contract via delegation, it's initially unpaused.
abstract contract Managed is UUPSUpgradeable {
    /// @notice The ERC-1967 name of the `pausedSlot` storage slot.
    string private constant PAUSED_SLOT_NAME = "eip1967.managed.paused";
    /// @notice The pointer to the storage slot with the boolean holding the paused state.
    bytes32 private immutable pausedSlot;

    /// @notice Emitted when the pause is triggered.
    /// @param caller The caller who triggered the change.
    event Paused(address caller);

    /// @notice Emitted when the pause is lifted.
    /// @param caller The caller who triggered the change.
    event Unpaused(address caller);

    /// @notice Initializes the contract in paused state and with no admin.
    /// The contract instance can be used only as a call delegation target for a proxy.
    constructor() {
        bytes32 pausedSlot_ = erc1967Slot(PAUSED_SLOT_NAME);
        pausedSlot = pausedSlot_;
        StorageSlot.getBooleanSlot(pausedSlot_).value = true;
    }

    /// @notice Throws if called by any caller other than the admin.
    modifier onlyAdmin() {
        require(admin() == msg.sender, "Caller is not the admin");
        _;
    }

    /// @notice Calculates the ERC-1967 slot pointer.
    /// @param name The name of the slot, should be globally unique
    /// @return slot The slot pointer
    function erc1967Slot(string memory name) internal pure returns (bytes32 slot) {
        return bytes32(uint256(keccak256(bytes(name))) - 1);
    }

    /// @notice Authorizes the contract upgrade. See `UUPSUpgradable` docs for more details.
    function _authorizeUpgrade(address newImplementation) internal view override onlyAdmin {
        newImplementation;
    }

    /// @notice Returns the address of the current admin.
    function admin() public view returns (address) {
        return _getAdmin();
    }

    /// @notice Changes the admin of the contract.
    /// Can only be called by the current admin.
    function changeAdmin(address newAdmin) public onlyAdmin {
        _changeAdmin(newAdmin);
    }

    /// @notice Returns true if the contract is paused, and false otherwise.
    function paused() public view returns (bool isPaused) {
        return _pausedSlot().value;
    }

    /// @notice Triggers stopped state.
    function pause() public onlyAdmin whenNotPaused {
        _pausedSlot().value = true;
        emit Paused(msg.sender);
    }

    /// @notice Returns to normal state.
    function unpause() public onlyAdmin whenPaused {
        _pausedSlot().value = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(!paused(), "Contract paused");
        _;
    }

    /// @notice Modifier to make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(paused(), "Contract not paused");
        _;
    }

    function _pausedSlot() private view returns (StorageSlot.BooleanSlot storage slot) {
        return StorageSlot.getBooleanSlot(pausedSlot);
    }
}

/// @notice A generic proxy for Managed.
contract Proxy is ERC1967Proxy {
    constructor(Managed logic, address admin) ERC1967Proxy(address(logic), new bytes(0)) {
        _changeAdmin(admin);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

/// @notice A splits receiver
struct SplitsReceiver {
    /// @notice The user ID.
    uint256 userId;
    /// @notice The splits weight. Must never be zero.
    /// The user will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the splitting user.
    uint32 weight;
}

library Splits {
    /// @notice Maximum number of splits receivers of a single user.
    /// Limits cost of collecting.
    uint32 public constant MAX_SPLITS_RECEIVERS = 200;
    /// @notice The total splits weight of a user
    uint32 public constant TOTAL_SPLITS_WEIGHT = 1_000_000;

    /// @notice Emitted when a user collects funds
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param collected The collected amount
    event Collected(uint256 indexed userId, uint256 indexed assetId, uint128 collected);

    /// @notice Emitted when funds are split from a user to a receiver.
    /// This is caused by the user collecting received funds.
    /// @param userId The user ID
    /// @param receiver The splits receiver user ID
    /// @param assetId The used asset ID
    /// @param amt The amount split to the receiver
    event Split(
        uint256 indexed userId,
        uint256 indexed receiver,
        uint256 indexed assetId,
        uint128 amt
    );

    /// @notice Emitted when funds are made collectable after splitting.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param amt The amount made collectable for the user on top of what was collectable before.
    event Collectable(uint256 indexed userId, uint256 indexed assetId, uint128 amt);

    /// @notice Emitted when funds are given from the user to the receiver.
    /// @param userId The user ID
    /// @param receiver The receiver user ID
    /// @param assetId The used asset ID
    /// @param amt The given amount
    event Given(
        uint256 indexed userId,
        uint256 indexed receiver,
        uint256 indexed assetId,
        uint128 amt
    );

    /// @notice Emitted when the user's splits are updated.
    /// @param userId The user ID
    /// @param receiversHash The splits receivers list hash
    event SplitsSet(uint256 indexed userId, bytes32 indexed receiversHash);

    /// @notice Emitted when a user is seen in a splits receivers list.
    /// @param receiversHash The splits receivers list hash
    /// @param userId The user ID.
    /// @param weight The splits weight. Must never be zero.
    /// The user will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the splitting user.
    event SplitsReceiverSeen(bytes32 indexed receiversHash, uint256 indexed userId, uint32 weight);

    struct Storage {
        /// @notice User splits states.
        /// The key is the user ID.
        mapping(uint256 => SplitsState) splitsStates;
    }

    struct SplitsState {
        /// @notice The user's splits configuration hash, see `hashSplits`.
        bytes32 splitsHash;
        /// @notice The user's splits balance. The key is the asset ID.
        mapping(uint256 => SplitsBalance) balances;
    }

    struct SplitsBalance {
        /// @notice The not yet split balance, must be split before collecting by the user.
        uint128 splittable;
        /// @notice The already split balance, ready to be collected by the user.
        uint128 collectable;
    }

    /// @notice Returns user's received but not split yet funds.
    /// @param userId The user ID
    /// @param assetId The used asset ID.
    /// @return amt The amount received but not split yet.
    function splittable(
        Storage storage s,
        uint256 userId,
        uint256 assetId
    ) internal view returns (uint128 amt) {
        return s.splitsStates[userId].balances[assetId].splittable;
    }

    /// @notice Calculate results of splitting an amount using the current splits configuration.
    /// @param userId The user ID
    /// @param currReceivers The list of the user's current splits receivers.
    /// @param amount The amount being split.
    /// @return collectableAmt The amount made collectable for the user
    /// on top of what was collectable before.
    /// @return splitAmt The amount split to the user's splits receivers
    function splitResults(
        Storage storage s,
        uint256 userId,
        SplitsReceiver[] memory currReceivers,
        uint128 amount
    ) internal view returns (uint128 collectableAmt, uint128 splitAmt) {
        assertCurrSplits(s, userId, currReceivers);
        if (amount == 0) return (0, 0);
        uint32 splitsWeight = 0;
        for (uint256 i = 0; i < currReceivers.length; i++) {
            splitsWeight += currReceivers[i].weight;
        }
        splitAmt = uint128((uint160(amount) * splitsWeight) / TOTAL_SPLITS_WEIGHT);
        collectableAmt = amount - splitAmt;
    }

    /// @notice Splits user's received but not split yet funds among receivers.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collectableAmt The amount made collectable for the user
    /// on top of what was collectable before.
    /// @return splitAmt The amount split to the user's splits receivers
    function split(
        Storage storage s,
        uint256 userId,
        uint256 assetId,
        SplitsReceiver[] memory currReceivers
    ) internal returns (uint128 collectableAmt, uint128 splitAmt) {
        assertCurrSplits(s, userId, currReceivers);
        mapping(uint256 => SplitsState) storage splitsStates = s.splitsStates;
        SplitsBalance storage balance = splitsStates[userId].balances[assetId];

        collectableAmt = balance.splittable;
        if (collectableAmt == 0) return (0, 0);

        balance.splittable = 0;
        uint32 splitsWeight = 0;
        for (uint256 i = 0; i < currReceivers.length; i++) {
            splitsWeight += currReceivers[i].weight;
            uint128 currSplitAmt = uint128(
                (uint160(collectableAmt) * splitsWeight) / TOTAL_SPLITS_WEIGHT - splitAmt
            );
            splitAmt += currSplitAmt;
            uint256 receiver = currReceivers[i].userId;
            splitsStates[receiver].balances[assetId].splittable += currSplitAmt;
            emit Split(userId, receiver, assetId, currSplitAmt);
        }
        collectableAmt -= splitAmt;
        balance.collectable += collectableAmt;
        emit Collectable(userId, assetId, collectableAmt);
    }

    /// @notice Returns user's received funds already split and ready to be collected.
    /// @param userId The user ID
    /// @param assetId The used asset ID.
    /// @return amt The collectable amount.
    function collectable(
        Storage storage s,
        uint256 userId,
        uint256 assetId
    ) internal view returns (uint128 amt) {
        return s.splitsStates[userId].balances[assetId].collectable;
    }

    /// @notice Collects user's received already split funds
    /// and transfers them out of the drips hub contract to msg.sender.
    /// @param userId The user ID
    /// @param assetId The used asset ID
    /// @return amt The collected amount
    function collect(
        Storage storage s,
        uint256 userId,
        uint256 assetId
    ) internal returns (uint128 amt) {
        SplitsBalance storage balance = s.splitsStates[userId].balances[assetId];
        amt = balance.collectable;
        balance.collectable = 0;
        emit Collected(userId, assetId, amt);
    }

    /// @notice Gives funds from the user to the receiver.
    /// The receiver can split and collect them immediately.
    /// Transfers the funds to be given from the user's wallet to the drips hub contract.
    /// @param userId The user ID
    /// @param receiver The receiver
    /// @param assetId The used asset ID
    /// @param amt The given amount
    function give(
        Storage storage s,
        uint256 userId,
        uint256 receiver,
        uint256 assetId,
        uint128 amt
    ) internal {
        s.splitsStates[receiver].balances[assetId].splittable += amt;
        emit Given(userId, receiver, assetId, amt);
    }

    /// @notice Sets user splits configuration.
    /// @param userId The user ID
    /// @param receivers The list of the user's splits receivers to be set.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the user.
    function setSplits(
        Storage storage s,
        uint256 userId,
        SplitsReceiver[] memory receivers
    ) internal {
        SplitsState storage state = s.splitsStates[userId];
        bytes32 newSplitsHash = hashSplits(receivers);
        emit SplitsSet(userId, newSplitsHash);
        if (newSplitsHash != state.splitsHash) {
            assertSplitsValid(receivers, newSplitsHash);
            state.splitsHash = newSplitsHash;
        }
    }

    /// @notice Validates a list of splits receivers and emits events for them
    /// @param receivers The list of splits receivers
    /// @param receiversHash The hash of the list of splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    function assertSplitsValid(SplitsReceiver[] memory receivers, bytes32 receiversHash) internal {
        require(receivers.length <= MAX_SPLITS_RECEIVERS, "Too many splits receivers");
        uint64 totalWeight = 0;
        uint256 prevUserId;
        for (uint256 i = 0; i < receivers.length; i++) {
            SplitsReceiver memory receiver = receivers[i];
            uint32 weight = receiver.weight;
            require(weight != 0, "Splits receiver weight is zero");
            totalWeight += weight;
            uint256 userId = receiver.userId;
            if (i > 0) {
                require(prevUserId != userId, "Duplicate splits receivers");
                require(prevUserId < userId, "Splits receivers not sorted by user ID");
            }
            prevUserId = userId;
            emit SplitsReceiverSeen(receiversHash, userId, weight);
        }
        require(totalWeight <= TOTAL_SPLITS_WEIGHT, "Splits weights sum too high");
    }

    /// @notice Asserts that the list of splits receivers is the user's currently used one.
    /// @param userId The user ID
    /// @param currReceivers The list of the user's current splits receivers.
    function assertCurrSplits(
        Storage storage s,
        uint256 userId,
        SplitsReceiver[] memory currReceivers
    ) internal view {
        require(
            hashSplits(currReceivers) == splitsHash(s, userId),
            "Invalid current splits receivers"
        );
    }

    /// @notice Current user's splits hash, see `hashSplits`.
    /// @param userId The user ID
    /// @return currSplitsHash The current user's splits hash
    function splitsHash(Storage storage s, uint256 userId)
        internal
        view
        returns (bytes32 currSplitsHash)
    {
        return s.splitsStates[userId].splitsHash;
    }

    /// @notice Calculates the hash of the list of splits receivers.
    /// @param receivers The list of the splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// @return receiversHash The hash of the list of splits receivers.
    function hashSplits(SplitsReceiver[] memory receivers)
        internal
        pure
        returns (bytes32 receiversHash)
    {
        if (receivers.length == 0) return bytes32(0);
        return keccak256(abi.encode(receivers));
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}