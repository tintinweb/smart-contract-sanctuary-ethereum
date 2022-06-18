// SPDX-License-Identifier: GPL-3.0 License

pragma solidity 0.8.7;

import "./BLXMRewardProvider.sol";
import "./interfaces/IBLXMStaker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IWETH.sol";

import "./libraries/TransferHelper.sol";
import "./libraries/BLXMLibrary.sol";


contract BLXMStaker is Initializable, BLXMRewardProvider, IBLXMStaker {
    using SafeMath for uint256;

    address public override BLXM;

    function initialize(address _BLXM) public initializer {
        __ReentrancyGuard_init();
        __BLXMMultiOwnable_init();

        updateRewardFactor(30, 1000000000000000000);
        updateRewardFactor(90, 1300000000000000000);
        updateRewardFactor(180, 1690000000000000000);
        updateRewardFactor(360, 2197000000000000000);

        BLXM = _BLXM;
    }

    function addRewards(uint256 totalBlxmAmount, uint16 supplyDays) external onlyOwner override returns (uint256 amountPerHours) {
        TransferHelper.safeTransferFrom(BLXM, msg.sender, getTreasury(), totalBlxmAmount);
        amountPerHours = _addRewards(totalBlxmAmount, supplyDays);
    }

    function stake(uint256 amount, address to, uint16 lockedDays) external override {
        require(amount > 0, "ZERO_AMOUNT");
        TransferHelper.safeTransferFrom(BLXM, msg.sender, getTreasury(), amount);
        _stake(to, amount, lockedDays);
    }

    function withdraw(uint256 amount, address to, uint256 idx) external override returns (uint256 rewardAmount) {
        require(amount > 0, "ZERO_AMOUNT");
        rewardAmount = _withdraw(to, amount, idx);
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity 0.8.7;

import "./interfaces/IBLXMRewardProvider.sol";
import "./BLXMTreasuryManager.sol";
import "./BLXMMultiOwnable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./libraries/SafeMath.sol";
import "./libraries/Math.sol";
import "./libraries/BLXMLibrary.sol";
import "./interfaces/IBLXMTreasury.sol";


contract BLXMRewardProvider is ReentrancyGuardUpgradeable, BLXMMultiOwnable, BLXMTreasuryManager, IBLXMRewardProvider {

    using SafeMath for uint;


    struct Field {
        uint32 syncHour; // at most sync once an hour
        uint totalAmount; // exclude extra amount
        uint pendingRewards;
        uint32 initialHour;
        uint16 lastSession;

        // days => session
        mapping(uint32 => uint16) daysToSession;

        // session => Period struct
        mapping(uint16 => Period) periods;

        // hours from the epoch => statistics
        mapping(uint32 => Statistics) dailyStatistics;
    }

    struct Period {
        uint amountPerHours;
        uint32 startHour; // include, timestamp in hour from initial hour
        uint32 endHour; // exclude, timestamp in hour from initial hour
    }

    struct Statistics {
        uint amountIn; // include extra amount
        uint amountOut;
        uint aggregatedRewards; // rewards / (amountIn - amountOut)
        uint32 next;
    }

    struct Position {
        uint amount;
        uint extraAmount;
        uint32 startHour; // include, hour from epoch, time to start calculating rewards
        uint32 endLocking; // exclude, hour from epoch, locked until this hour
    }

    Field private treasuryFields;

    // user address => idx => position
    mapping(address => Position[]) public override allPosition;

    // locked days => factor
    mapping(uint16 => uint) internal rewardFactor;


    modifier sync() {
        syncStatistics();
        _;
    }

    function updateRewardFactor(uint16 lockedDays, uint factor) public override onlyOwner returns (bool) {
        require(lockedDays != 0, 'ZERO_DAYS');
        require(factor == 0 || factor >= 10 ** decimals(), 'WRONG_FACTOR');
        uint oldFactor = rewardFactor[lockedDays];
        rewardFactor[lockedDays] = factor;

        emit UpdateRewardFactor(msg.sender, oldFactor, factor);
        return true;
    }

    function getRewardFactor(uint16 lockedDays) external override view returns (uint factor) {
        factor = rewardFactor[lockedDays];
    }

    function allPositionLength(address investor) public override view returns (uint) {
        return allPosition[investor].length;
    }

    // ** DO NOT CALL THIS FUNCTION AS A WRITE FUNCTION **
    function calcRewards(address investor, uint idx) external override sync returns (uint rewardAmount, bool isLocked) {
        require(idx < allPositionLength(investor), 'NO_POSITION');
        Position memory position = allPosition[investor][idx];
        (rewardAmount, isLocked) = _calcRewards(position);
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

    function getDailyStatistics(uint32 hourFromEpoch) external view override returns (uint amountIn, uint amountOut, uint aggregatedRewards, uint32 next) {
        Statistics memory statistics = treasuryFields.dailyStatistics[hourFromEpoch];
        amountIn = statistics.amountIn;
        amountOut = statistics.amountOut;
        aggregatedRewards = statistics.aggregatedRewards;
        next = statistics.next;
    }

    function hoursToSession(uint32 hourFromEpoch) external override view returns (uint16 session) {
        uint32 initialHour = treasuryFields.initialHour;
        if (hourFromEpoch >= initialHour) {
            uint32 hour = hourFromEpoch - initialHour;
            session = treasuryFields.daysToSession[hour / 24];
        }
    }

    function getPeriods(uint16 session) external override view returns (uint amountPerHours, uint32 startHour, uint32 endHour) {
        Period storage period = treasuryFields.periods[session];
        amountPerHours = period.amountPerHours;

        uint32 initialHour = treasuryFields.initialHour;
        startHour = period.startHour;
        endHour = period.endHour;
        
        if (startHour != 0 || endHour != 0) {
            startHour += initialHour;
            endHour += initialHour;
        }
    }

    function getTreasuryFields() external view override returns(uint32 syncHour, uint totalAmount, uint pendingRewards, uint32 initialHour, uint16 lastSession) {
        syncHour = treasuryFields.syncHour;
        totalAmount = treasuryFields.totalAmount;
        pendingRewards = treasuryFields.pendingRewards;
        initialHour = treasuryFields.initialHour;
        lastSession = treasuryFields.lastSession;
    }

    // should sync statistics every time before amount or rewards change
    function syncStatistics() public override {
        uint32 currentHour = BLXMLibrary.currentHour();
        uint32 syncHour = treasuryFields.syncHour;

        if (syncHour < currentHour) {
            if (syncHour != 0) {
                _updateStatistics(syncHour, currentHour);
            }
            treasuryFields.syncHour = currentHour;
        }
    }

    function _addRewards(uint totalAmount, uint16 supplyDays) internal nonReentrant sync returns (uint amountPerHours) {
        require(totalAmount > 0 && supplyDays > 0, 'ZERO_REWARDS');

        uint16 lastSession = treasuryFields.lastSession;
        if (lastSession == 0) {
            treasuryFields.initialHour = BLXMLibrary.currentHour();
        }

        uint32 startHour = treasuryFields.periods[lastSession].endHour;
        uint32 endHour = startHour + (supplyDays * 24);

        lastSession += 1;
        treasuryFields.lastSession = lastSession;

        uint32 target = startHour / 24;
        uint32 i = endHour / 24;
        unchecked {
            while (i --> target) {
                // reverse mapping
                treasuryFields.daysToSession[i] = lastSession;
            }
        }

        amountPerHours = totalAmount / (supplyDays * 24);
        treasuryFields.periods[lastSession] = Period(amountPerHours, startHour, endHour);

        if (treasuryFields.pendingRewards != 0) {
            uint pendingRewards = treasuryFields.pendingRewards;
            treasuryFields.pendingRewards = 0;
            _arrangeFailedRewards(pendingRewards);
        }

        uint32 initialHour = treasuryFields.initialHour;
        _addRewards(totalAmount);
        emit AddRewards(msg.sender, initialHour + startHour, initialHour + endHour, amountPerHours);
    }

    // if (is locked) {
    //     (amount + extra amount) * (agg now - agg hour in)
    // } else {
    //     amount * (agg now - agg day in)
    //     extra amount * (agg end locking - agg hour in)
    // }
    function _calcRewards(Position memory position) internal view returns (uint rewardAmount, bool isLocked) {

        uint32 currentHour = BLXMLibrary.currentHour();
        require(treasuryFields.syncHour == currentHour, 'NOT_SYNC');

        if (currentHour < position.startHour) {
            return (0, true);
        }

        if (currentHour < position.endLocking) {
            isLocked = true;
        }

        uint amount = position.amount;
        uint extraAmount = position.extraAmount;
        
        uint aggNow = treasuryFields.dailyStatistics[currentHour].aggregatedRewards;
        uint aggStart = treasuryFields.dailyStatistics[position.startHour].aggregatedRewards;
        if (isLocked) {
            rewardAmount = amount.add(extraAmount).wmul(aggNow.sub(aggStart));
        } else {
            uint aggEnd = treasuryFields.dailyStatistics[position.endLocking].aggregatedRewards;
            if (extraAmount != 0) {
                rewardAmount = extraAmount.wmul(aggEnd.sub(aggStart));
            }
            rewardAmount = rewardAmount.add(amount.wmul(aggNow.sub(aggStart)));
        }
    }

    function _stake(address to, uint amount, uint16 lockedDays) internal nonReentrant sync {
        require(amount != 0, 'INSUFFICIENT_AMOUNT');
        uint256 _factor = rewardFactor[lockedDays];
        require(_factor != 0, 'NO_FACTOR');

        uint extraAmount = amount.wmul(_factor.sub(10 ** decimals()));

        uint32 startHour = BLXMLibrary.currentHour() + 1;
        uint32 endLocking = startHour + (lockedDays * 24);

        allPosition[to].push(Position(amount, extraAmount, startHour, endLocking));
        
        _updateAmount(startHour, amount.add(extraAmount), 0);
        if (extraAmount != 0) {
            _updateAmount(endLocking, 0, extraAmount);
        }

        treasuryFields.totalAmount = amount.add(treasuryFields.totalAmount);

        _notify(amount, to);
        emit Stake(msg.sender, amount, to);
        _emitAllPosition(to, allPositionLength(to) - 1);
    }

    function _withdraw(address to, uint amount, uint idx) internal nonReentrant sync returns (uint rewardAmount) {
        require(idx < allPositionLength(msg.sender), 'NO_POSITION');
        Position memory position = allPosition[msg.sender][idx];
        require(amount > 0 && amount <= position.amount, 'INSUFFICIENT_AMOUNT');

        // The start hour must be a full hour, 
        // when add and remove on the same hour, 
        // the next hour's amount should be subtracted.
        uint32 hour = BLXMLibrary.currentHour();
        hour = hour >= position.startHour ? hour : position.startHour;
        _updateAmount(hour, 0, amount);

        uint extraAmount = position.extraAmount * amount / position.amount;

        bool isLocked;
        (rewardAmount, isLocked) = _calcRewards(position);
        rewardAmount = rewardAmount * amount / position.amount;
        if (isLocked) {
            _arrangeFailedRewards(rewardAmount);
            rewardAmount = 0;
            _updateAmount(hour, 0, extraAmount);
            _updateAmount(position.endLocking, extraAmount, 0);
        }

        allPosition[msg.sender][idx].amount = position.amount.sub(amount);
        allPosition[msg.sender][idx].extraAmount = position.extraAmount.sub(extraAmount);
        
        uint _totalAmount = treasuryFields.totalAmount;
        treasuryFields.totalAmount = _totalAmount.sub(amount);

        _withdraw(msg.sender, amount, rewardAmount, to);
        emit Withdraw(msg.sender, amount, rewardAmount, to);
        _emitAllPosition(msg.sender, idx);
    }

    function _arrangeFailedRewards(uint rewardAmount) internal {
        if (rewardAmount == 0) {
            return;
        }
        uint32 initialHour = treasuryFields.initialHour;
        uint32 startHour = BLXMLibrary.currentHour() - initialHour;
        uint16 session = treasuryFields.daysToSession[startHour / 24];
        if (session == 0) {
            treasuryFields.pendingRewards += rewardAmount;
            return;
        }

        uint32 endHour = treasuryFields.periods[session].endHour;
        uint32 leftHour = endHour - startHour;
        uint amountPerHours = rewardAmount / leftHour;
        treasuryFields.periods[session].amountPerHours += amountPerHours;

        emit ArrangeFailedRewards(msg.sender, initialHour + startHour, initialHour + endHour, amountPerHours);
    }

    function _emitAllPosition(address owner, uint idx) internal {
        Position memory position = allPosition[owner][idx];
        emit AllPosition(owner, position.amount, position.extraAmount, position.startHour, position.endLocking, idx);
    }

    function _updateAmount(uint32 hour, uint amountIn, uint amountOut) internal {
        require(hour >= BLXMLibrary.currentHour(), 'DATA_FIXED');
        Statistics memory statistics = treasuryFields.dailyStatistics[hour];
        statistics.amountIn = statistics.amountIn.add(amountIn);
        statistics.amountOut = statistics.amountOut.add(amountOut);
        treasuryFields.dailyStatistics[hour] = statistics;
    }

    function _updateStatistics(uint32 fromHour, uint32 toHour) internal {
        Statistics storage statistics = treasuryFields.dailyStatistics[fromHour];
        uint amountIn = statistics.amountIn;
        uint amountOut = statistics.amountOut;
        uint aggregatedRewards = statistics.aggregatedRewards;
        uint32 prev = fromHour; // point to previous statistics
        while (fromHour < toHour) {
            uint amount = amountIn.sub(amountOut);
            uint rewards = treasuryFields.periods[treasuryFields.daysToSession[(fromHour - treasuryFields.initialHour) / 24]].amountPerHours;

            if (amount != 0) {
                aggregatedRewards = aggregatedRewards.add(rewards.wdiv(amount));
            }

            fromHour += 1;
            statistics = treasuryFields.dailyStatistics[fromHour];

            if (statistics.amountIn != 0 || statistics.amountOut != 0 || fromHour == toHour) {
                statistics.aggregatedRewards = aggregatedRewards;
                statistics.amountIn = amountIn = amountIn.add(statistics.amountIn);
                statistics.amountOut = amountOut = amountOut.add(statistics.amountOut);
                treasuryFields.dailyStatistics[prev].next = fromHour;
                prev = fromHour;

                emit SyncStatistics(msg.sender, amountIn, amountOut, aggregatedRewards, fromHour);
            }
        }
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMStaker {

    function BLXM() external view returns (address);

    function addRewards(uint totalBlxmAmount, uint16 supplyDays) external returns (uint amountPerHours);
    function stake(uint256 amount, address to, uint16 lockedDays) external;
    function withdraw(uint256 amount, address to, uint256 idx) external returns (uint256 rewardAmount);
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

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferCurrency(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: CURRENCY_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


library BLXMLibrary {

    function validateAddress(address _address) internal pure {
        // reduce contract size
        require(_address != address(0), "ZERO_ADDRESS");
    }

    function currentHour() internal view returns(uint32) {
        return uint32(block.timestamp / 1 hours);
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMRewardProvider {

    event Stake(address indexed sender, uint amount, address indexed to);
    event Withdraw(address indexed sender, uint amount, uint rewardAmount, address indexed to);

    event AddRewards(address indexed sender, uint32 startHour, uint32 endHour, uint amountPerHours);
    event ArrangeFailedRewards(address indexed sender, uint32 startHour, uint32 endHour, uint amountPerHours);
    event AllPosition(address indexed owner, uint amount, uint extraAmount, uint32 startHour, uint32 endLocking, uint indexed idx);
    event SyncStatistics(address indexed sender, uint amountIn, uint amountOut, uint aggregatedRewards, uint32 hour);
    event UpdateRewardFactor(address indexed sender, uint oldFactor, uint newFactor);

    function getRewardFactor(uint16 _days) external view returns (uint factor);
    function updateRewardFactor(uint16 lockedDays, uint factor) external returns (bool);

    function allPosition(address investor, uint idx) external view returns(uint amount, uint extraAmount, uint32 startHour, uint32 endLocking);
    function allPositionLength(address investor) external view returns (uint);
    function calcRewards(address investor, uint idx) external returns (uint rewardAmount, bool isLocked);
    
    function getTreasuryFields() external view returns (uint32 syncHour, uint totalAmount, uint pendingRewards, uint32 initialHour, uint16 lastSession);
    function getDailyStatistics(uint32 hourFromEpoch) external view returns (uint amountIn, uint amountOut, uint aggregatedRewards, uint32 next);
    function syncStatistics() external;
    function hoursToSession(uint32 hourFromEpoch) external view returns (uint16 session);
    function getPeriods(uint16 session) external view returns (uint amountPerHours, uint32 startHour, uint32 endHour);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity 0.8.7;

import "./interfaces/IBLXMTreasuryManager.sol";
import "./BLXMMultiOwnable.sol";

import "./interfaces/IBLXMTreasury.sol";
import "./libraries/BLXMLibrary.sol";


contract BLXMTreasuryManager is BLXMMultiOwnable, IBLXMTreasuryManager {

    address internal treasury;


    function getTreasury() public override view returns (address _treasury) {
        require(treasury != address(0), 'TSC_NOT_FOUND');
        _treasury = treasury;
    }

    function updateTreasury(address _treasury) external override onlyOwner {
        require(IBLXMTreasury(_treasury).SSC() == address(this), 'INVALID_TSC');
        address oldTreasury = treasury;
        treasury = _treasury;
        emit UpdateTreasury(msg.sender, oldTreasury, _treasury);
    }

    function getReserves() public view override returns (uint reserveBlxm, uint totalRewrads) {
        reserveBlxm = IBLXMTreasury(getTreasury()).totalBlxm();
        totalRewrads = IBLXMTreasury(getTreasury()).totalRewards();
    }

    function _addRewards(uint amount) internal {
        IBLXMTreasury(getTreasury()).addRewards(amount);
    }

    function _withdraw(address from, uint amount, uint rewards, address to) internal {
        IBLXMTreasury(getTreasury()).retrieveBlxmTokens(from, amount, rewards, to);
    }

    function _notify(uint amount, address to) internal {
        IBLXMTreasury(getTreasury()).addBlxmTokens(amount, to);
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/BLXMLibrary.sol";


abstract contract BLXMMultiOwnable is Initializable {
    
    // member address => permission
    mapping(address => bool) public members;

    event OwnershipChanged(address indexed executeOwner, address indexed targetOwner, bool permission);

    modifier onlyOwner() {
        require(members[msg.sender], "NOT_OWNER");
        _;
    }

    function __BLXMMultiOwnable_init() internal onlyInitializing {
        _changeOwnership(msg.sender, true);
    }

    function addOwnership(address newOwner) public virtual onlyOwner {
        BLXMLibrary.validateAddress(newOwner);
        _changeOwnership(newOwner, true);
    }

    function removeOwnership(address owner) public virtual onlyOwner {
        BLXMLibrary.validateAddress(owner);
        _changeOwnership(owner, false);
    }

    function _changeOwnership(address owner, bool permission) internal virtual {
        members[owner] = permission;
        emit OwnershipChanged(msg.sender, owner, permission);
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    uint constant WAD = 10 ** 18;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMTreasury {

    event SendTokensToWhitelistedWallet(address indexed sender, uint amount, address indexed receiver);
    event Whitelist(address indexed sender, bool permission, address indexed wallet);


    function BLXM() external returns (address blxm);
    function SSC() external returns (address ssc);

    function addWhitelist(address wallet) external;
    function removeWhitelist(address wallet) external;
    function whitelist(address wallet) external returns (bool permission);

    function totalBlxm() external view returns (uint totalBlxm);
    function totalRewards() external view returns (uint totalRewards);
    function balanceOf(address investor) external view returns (uint balance);

    function addRewards(uint amount) external;

    function addBlxmTokens(uint amount, address to) external;
    function retrieveBlxmTokens(address from, uint amount, uint rewardAmount, address to) external;

    function sendTokensToWhitelistedWallet(uint amount, address to) external;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMTreasuryManager {

    event UpdateTreasury(address indexed sender, address oldTreasury, address newTreasury);

    function updateTreasury(address treasury) external;
    function getTreasury() external returns (address treasury);

    function getReserves() external view returns (uint reserveBlxm, uint totalRewrads);
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