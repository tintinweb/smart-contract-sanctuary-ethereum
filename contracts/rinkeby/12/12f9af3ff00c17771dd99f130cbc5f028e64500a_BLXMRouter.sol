// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./BLXMRewardProvider.sol";
import "./interfaces/IBLXMRouter.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IWETH.sol";

import "./libraries/TransferHelper.sol";
import "./libraries/BLXMLibrary.sol";


contract BLXMRouter is Initializable, BLXMRewardProvider, IBLXMRouter {

    using SafeMath for uint;

    address public override BLXM;
    address public override WETH;


    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH/BNB via fallback from the WETH contract
    }

    function initialize(address _BLXM, address _WETH) public initializer {
        __ReentrancyGuard_init();
        __BLXMMultiOwnable_init();
        
        updateRewardFactor(30, 1100000000000000000); // 1.1
        updateRewardFactor(60, 1210000000000000000); // 1.21
        updateRewardFactor(90, 1331000000000000000); // 1.331
        
        exclude[_BLXM] = true;
        BLXM = _BLXM;
        WETH = _WETH;
    }

    function addRewards(address token, uint totalBlxmAmount, uint16 supplyDays) external override returns (uint amountPerHours) {
        TransferHelper.safeTransferFrom(BLXM, msg.sender, getTreasury(token), totalBlxmAmount);
        amountPerHours = _addRewards(token, totalBlxmAmount, supplyDays);
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address token,
        uint amountBlxmDesired,
        uint amountTokenDesired,
        uint amountBlxmMin,
        uint amountTokenMin
    ) private view returns (uint amountBlxm, uint amountToken) {
        _validateToken(token);

        (uint ratio, uint blockNumberLast) = getRatio(token);
        require(blockNumberLast > block.number, 'RATIO_EXPIRED');

        uint amountTokenOptimal = amountBlxmDesired.wdiv(ratio);
        if (amountTokenOptimal <= amountTokenDesired) {
            require(amountTokenOptimal >= amountTokenMin, 'INSUFFICIENT_BLXM_AMOUNT');
            (amountBlxm, amountToken) = (amountBlxmDesired, amountTokenOptimal);
        } else {
            uint amountBlxmOptimal = amountTokenDesired.wmul(ratio);
            assert(amountBlxmOptimal <= amountBlxmDesired);
            require(amountBlxmOptimal >= amountBlxmMin, 'INSUFFICIENT_TOKEN_AMOUNT');
            (amountBlxm, amountToken) = (amountBlxmOptimal, amountTokenDesired);
        }
    }

    function addLiquidity(
        address token,
        uint amountBlxmDesired,
        uint amountTokenDesired,
        uint amountBlxmMin,
        uint amountTokenMin,
        address to,
        uint deadline,
        uint16 lockedDays
    ) external override ensure(deadline) returns (uint amountBlxm, uint amountToken, uint liquidity) {
        (amountBlxm, amountToken) = _addLiquidity(token, amountBlxmDesired, amountTokenDesired, amountBlxmMin, amountTokenMin);
        address treasury = getTreasury(token);
        TransferHelper.safeTransferFrom(BLXM, msg.sender, treasury, amountBlxm);
        TransferHelper.safeTransferFrom(token, msg.sender, treasury, amountToken);
        liquidity = _mint(to, token, amountBlxm, amountToken, lockedDays);
    }

    function addLiquidityETH(
        uint amountBlxmDesired,
        uint amountBlxmMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint16 lockedDays
    ) external override payable ensure(deadline) returns (uint amountBlxm, uint amountETH, uint liquidity) {
        (amountBlxm, amountETH) = _addLiquidity(WETH, amountBlxmDesired, msg.value, amountBlxmMin, amountETHMin);
        address treasury = getTreasury(WETH);
        TransferHelper.safeTransferFrom(BLXM, msg.sender, treasury, amountBlxm);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(treasury, amountETH));
        liquidity = _mint(to, WETH, amountBlxm, amountETH, lockedDays);
        if (msg.value > amountETH) TransferHelper.safeTransferCurrency(msg.sender, msg.value - amountETH); // refund dust, if any
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        uint liquidity,
        uint amountBlxmMin,
        uint amountTokenMin,
        address to,
        uint deadline,
        uint idx
    ) public override ensure(deadline) returns (uint amountBlxm, uint amountToken, uint rewards) {
        (amountBlxm, amountToken, rewards) = _burn(to, liquidity, idx);
        require(amountBlxm - rewards >= amountBlxmMin, 'INSUFFICIENT_BLXM_AMOUNT');
        require(amountToken >= amountTokenMin, 'INSUFFICIENT_TOKEN_AMOUNT');
    }
    
    function removeLiquidityETH(
        uint liquidity,
        uint amountBlxmMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint idx
    ) public override ensure(deadline) returns (uint amountBlxm, uint amountETH, uint rewards) {
        (amountBlxm, amountETH, rewards) = removeLiquidity(liquidity, amountBlxmMin, amountETHMin, address(this), deadline, idx);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferCurrency(to, amountETH);
        TransferHelper.safeTransfer(BLXM, to, amountBlxm);
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./interfaces/IBLXMRewardProvider.sol";
import "./BLXMTreasuryManager.sol";
import "./BLXMMultiOwnable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./libraries/SafeMath.sol";
import "./libraries/Math.sol";
import "./libraries/BLXMLibrary.sol";


contract BLXMRewardProvider is ReentrancyGuardUpgradeable, BLXMMultiOwnable, BLXMTreasuryManager, IBLXMRewardProvider {

    using SafeMath for uint;

    struct Field {
        uint32 syncHour; // at most sync once an hour
        uint totalLiquidity; // exclude extra liquidity
        uint pendingRewards;
        uint32 initialHour;
        uint16 lastSession;

        // days => session
        mapping(uint32 => uint16) daysToSession;

        // session => Period struct
        mapping(uint16 => Period) periods;

        // hours from the epoch => statistics
        mapping(uint32 => Statistics) dailyStatistics;

        uint ratio; // BLXM : token
        uint blockNumberLast;
    }

    struct Period {
        uint amountPerHours;
        uint32 startHour; // include, timestamp in hour from initial hour
        uint32 endHour; // exclude, timestamp in hour from initial hour
    }

    struct Statistics {
        uint liquidityIn; // include extra liquidity
        uint liquidityOut;
        uint aggregatedRewards; // rewards / (liquidityIn - liquidityOut)
        uint32 next;
    }

    struct Position {
        address token; // (another pair from blxm)
        uint liquidity;
        uint extraLiquidity;
        uint32 startHour; // include, hour from epoch, time to start calculating rewards
        uint32 endLocking; // exclude, hour from epoch, locked until this hour
    }

    // token (another pair from blxm) => Field
    mapping(address => Field) private treasuryFields;

    // user address => idx => position
    mapping(address => Position[]) public override allPosition;

    // locked days => factor
    mapping(uint16 => uint) internal rewardFactor;


    function updateRewardFactor(uint16 lockedDays, uint factor) public override onlyOwner returns (bool) {
        require(lockedDays != 0, 'ZERO_DAYS');
        rewardFactor[lockedDays] = factor.sub(10 ** 18);
        return true;
    }

    function getRewardFactor(uint16 lockedDays) external override view returns (uint factor) {
        factor = rewardFactor[lockedDays];
        factor = factor.add(10 ** 18);
    }

    function allPositionLength(address investor) public override view returns (uint) {
        return allPosition[investor].length;
    }

    function _addRewards(address token, uint totalAmount, uint16 supplyDays) internal nonReentrant onlyOwner returns (uint amountPerHours) {
        require(totalAmount > 0 && supplyDays > 0, 'ZERO_REWARDS');
        _syncStatistics(token);

        Field storage field = treasuryFields[token];

        uint16 lastSession = field.lastSession;
        if (lastSession == 0) {
            field.initialHour = BLXMLibrary.currentHour();
        }

        uint32 startHour = field.periods[lastSession].endHour;
        uint32 endHour = startHour + (supplyDays * 24);

        lastSession += 1;
        field.lastSession = lastSession;

        uint32 target = startHour / 24;
        uint32 i = endHour / 24;
        unchecked {
            while (i --> target) {
                // reverse mapping
                field.daysToSession[i] = lastSession;
            }
        }

        amountPerHours = totalAmount / (supplyDays * 24);
        field.periods[lastSession] = Period(amountPerHours, startHour, endHour);

        if (field.pendingRewards != 0) {
            _arrangeFailedRewards(token, field.pendingRewards);
            field.pendingRewards = 0;
        }
        emit AddRewards(msg.sender, lastSession, amountPerHours);
    }

    function calcRewards(address investor, uint idx) external override view returns (uint amount, bool isLocked) {
        require(idx < allPositionLength(investor), 'NO_POSITION');
        (amount, isLocked) = _calcRewards(allPosition[investor][idx]);
    }

    function syncStatistics(address token) public override {
        BLXMLibrary.validateAddress(treasurys[token]);
        _syncStatistics(token);
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

    function getDailyStatistics(address token, uint32 hourFromEpoch) external view override returns (uint liquidityIn, uint liquidityOut, uint aggregatedRewards, uint32 next) {
        Statistics memory statistics = treasuryFields[token].dailyStatistics[hourFromEpoch];
        liquidityIn = statistics.liquidityIn;
        liquidityOut = statistics.liquidityOut;
        aggregatedRewards = statistics.aggregatedRewards;
        next = statistics.next;
    }

    function hoursToSession(address token, uint32 hourFromEpoch) external override view returns (uint16 session) {
        Field storage field = treasuryFields[token];
        if (hourFromEpoch >= field.initialHour) {
            uint32 hour = hourFromEpoch - field.initialHour;
            session = field.daysToSession[hour / 24];
        }
    }

    function getPeriods(address token, uint16 session) external override view returns (uint amountPerHours, uint32 startHour, uint32 endHour) {
        Period storage period = treasuryFields[token].periods[session];
        amountPerHours = period.amountPerHours;
        startHour = period.startHour;
        endHour = period.endHour;
    }

    function getTreasuryFields(address token) external view override returns(uint32 syncHour, uint totalLiquidity, uint pendingRewards, uint32 initialHour, uint16 lastSession) {
        Field storage fields = treasuryFields[token];
        syncHour = fields.syncHour;
        totalLiquidity = fields.totalLiquidity;
        pendingRewards = fields.pendingRewards;
        initialHour = fields.initialHour;
        lastSession = fields.lastSession;
    }

    function getRatio(address token) public view override returns (uint ratio, uint blockNumberLast) {
        Field storage fields = treasuryFields[token];
        ratio = fields.ratio;
        blockNumberLast = fields.blockNumberLast;
    }

    function updateRatio(address token, uint ratio, uint interval) external override onlyOwner {
        getTreasury(token);
        Field storage fields = treasuryFields[token];
        uint blockNumberLast = block.number + interval;
        fields.ratio = ratio;
        fields.blockNumberLast = blockNumberLast;
        emit UpdateRatio(msg.sender, token, ratio, blockNumberLast);
    }

    // if (is locked) {
    //     (liquidity + extra liquidity) * (agg now - agg hour in)
    // } else {
    //     liquidity * (agg now - agg day in)
    //     extra liquidity * (agg end locking - agg hour in)
    // }
    function _calcRewards(Position memory position) internal view returns (uint amount, bool isLocked) {

        uint32 currentHour = BLXMLibrary.currentHour();
        require(treasuryFields[position.token].syncHour == currentHour, 'NOT_SYNC');

        if (currentHour < position.startHour) {
            return (0, true);
        }

        if (currentHour < position.endLocking) {
            isLocked = true;
        }

        uint liquidity = position.liquidity;
        uint extraLiquidity = position.extraLiquidity;
        
        Field storage field = treasuryFields[position.token];
        uint aggNow = field.dailyStatistics[currentHour].aggregatedRewards;
        uint aggStart = field.dailyStatistics[position.startHour].aggregatedRewards;
        if (isLocked) {
            amount = liquidity.add(extraLiquidity).wmul(aggNow.sub(aggStart));
        } else {
            uint aggEnd = field.dailyStatistics[position.endLocking].aggregatedRewards;
            amount = extraLiquidity.wmul(aggEnd.sub(aggStart));
            amount = amount.add(liquidity.wmul(aggNow.sub(aggStart)));
        }
    }

    function _mint(address to, address token, uint amountBlxm, uint amountToken, uint16 lockedDays) internal nonReentrant returns (uint liquidity) {
        liquidity = Math.sqrt(amountBlxm.mul(amountToken));
        require(liquidity != 0, 'INSUFFICIENT_LIQUIDITY');
        _syncStatistics(token);

        uint extraLiquidity = liquidity.wmul(rewardFactor[lockedDays]);

        uint32 startHour = BLXMLibrary.currentHour() + 1;
        uint32 endLocking = startHour + (lockedDays * 24);

        allPosition[to].push(Position(token, liquidity, extraLiquidity, startHour, endLocking));
        
        _updateLiquidity(token, startHour, liquidity.add(extraLiquidity), 0);
        if (extraLiquidity != 0) {
            _updateLiquidity(token, endLocking, 0, extraLiquidity);
        }

        treasuryFields[token].totalLiquidity = liquidity.add(treasuryFields[token].totalLiquidity);

        _notify(getTreasury(token), amountBlxm, amountToken, to);
        emit Mint(msg.sender, amountBlxm, amountToken);
    }

    function _burn(address to, uint liquidity, uint idx) internal nonReentrant returns (uint amountBlxm, uint amountToken, uint rewardAmount) {
        require(idx < allPositionLength(msg.sender), 'NO_POSITION');
        Position memory position = allPosition[msg.sender][idx];
        require(liquidity > 0 && liquidity <= position.liquidity, 'INSUFFICIENT_LIQUIDITY');
        _syncStatistics(position.token);

        // The start day must be a full day, 
        // when add and remove on the same day, 
        // the next day's liquidity should be subtracted.
        uint32 hour = BLXMLibrary.currentHour();
        hour = hour >= position.startHour ? hour : position.startHour;
        _updateLiquidity(position.token, hour, 0, liquidity);

        uint extraLiquidity = position.extraLiquidity * liquidity / position.liquidity;

        bool isLocked;
        (rewardAmount, isLocked) = _calcRewards(position);
        rewardAmount = rewardAmount * liquidity / position.liquidity;
        if (isLocked) {
            _arrangeFailedRewards(position.token, rewardAmount);
            rewardAmount = 0;
            _updateLiquidity(position.token, hour, 0, extraLiquidity);
            _updateLiquidity(position.token, position.endLocking, extraLiquidity, 0);
        }

        allPosition[msg.sender][idx].liquidity = position.liquidity.sub(liquidity);
        allPosition[msg.sender][idx].extraLiquidity = position.extraLiquidity.sub(extraLiquidity);
        
        uint _totalLiquidity = treasuryFields[position.token].totalLiquidity;
        treasuryFields[position.token].totalLiquidity = _totalLiquidity.sub(liquidity);

        (amountBlxm, amountToken) = _withdraw(getTreasury(position.token), rewardAmount, liquidity, _totalLiquidity, to);
        emit Burn(msg.sender, amountBlxm, amountToken, rewardAmount, to);
    }

    function _arrangeFailedRewards(address token, uint rewardAmount) internal {
        if (rewardAmount == 0) {
            return;
        }
        Field storage field = treasuryFields[token];
        uint32 startHour = BLXMLibrary.currentHour() - field.initialHour;
        uint16 session = field.daysToSession[startHour / 24];
        if (session == 0) {
            field.pendingRewards += rewardAmount; 
            return;
        }

        uint32 endHour = field.periods[session].endHour;
        uint32 leftHour = endHour - startHour;
        uint amountPerHours = rewardAmount / leftHour;
        field.periods[session].amountPerHours += amountPerHours;
        emit ArrangeFailedRewards(msg.sender, startHour, endHour, amountPerHours);
    }

    function _updateLiquidity(address token, uint32 hour, uint liquidityIn, uint liquidityOut) internal {
        require(hour >= BLXMLibrary.currentHour(), 'DATA_FIXED');
        Field storage field = treasuryFields[token];
        Statistics memory statistics = field.dailyStatistics[hour];
        statistics.liquidityIn = statistics.liquidityIn.add(liquidityIn);
        statistics.liquidityOut = statistics.liquidityOut.add(liquidityOut);
        field.dailyStatistics[hour] = statistics;
    }

    // should sync statistics every time before liquidity or rewards change
    function _syncStatistics(address token) internal {
        uint32 currentHour = BLXMLibrary.currentHour();
        Field storage field = treasuryFields[token];
        uint32 syncHour = field.syncHour;

        if (syncHour < currentHour) {
            if (syncHour != 0) {
                _updateStatistics(field, syncHour, currentHour);
            }
            field.syncHour = currentHour;
        }
    }

    function _updateStatistics(Field storage field, uint32 fromHour, uint32 toHour) internal {
        Statistics storage statistics = field.dailyStatistics[fromHour];
        uint liquidityIn = statistics.liquidityIn;
        uint liquidityOut = statistics.liquidityOut;
        uint aggregatedRewards = statistics.aggregatedRewards;
        uint32 prev = fromHour; // point to previous statistics
        while (fromHour < toHour) {
            uint liquidity = liquidityIn.sub(liquidityOut);
            uint rewards = field.periods[field.daysToSession[(fromHour - field.initialHour) / 24]].amountPerHours;

            if (liquidity != 0) {
                aggregatedRewards = aggregatedRewards.add(rewards.wdiv(liquidity));
            }

            fromHour += 1;
            statistics = field.dailyStatistics[fromHour];

            if (statistics.liquidityIn != 0 || statistics.liquidityOut != 0 || fromHour == toHour) {
                statistics.aggregatedRewards = aggregatedRewards;
                statistics.liquidityIn = liquidityIn = liquidityIn.add(statistics.liquidityIn);
                statistics.liquidityOut = liquidityOut = liquidityOut.add(statistics.liquidityOut);
                field.dailyStatistics[prev].next = fromHour;
                prev = fromHour;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMRouter {

    function BLXM() external view returns (address);
    function WETH() external view returns (address);

    function addRewards(address token, uint totalBlxmAmount, uint16 supplyDays) external returns (uint amountPerHours);

    function addLiquidity(
        address token,
        uint amountBlxmDesired,
        uint amountTokenDesired,
        uint amountBlxmMin,
        uint amountTokenMin,
        address to,
        uint deadline,
        uint16 lockedDays
    ) external returns (uint amountBlxm, uint amountToken, uint liquidity);
    function addLiquidityETH(
        uint amountBlxmDesired,
        uint amountBlxmMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint16 lockedDays
    ) external payable returns (uint amountBlxm, uint amountETH, uint liquidity);

    function removeLiquidity(
        uint liquidity,
        uint amountBlxmMin,
        uint amountTokenMin,
        address to,
        uint deadline,
        uint idx
    ) external returns (uint amountBlxm, uint amountToken, uint rewards);
    function removeLiquidityETH(
        uint liquidity,
        uint amountBlxmMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint idx
    ) external returns (uint amountBlxm, uint amountETH, uint rewards);
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

import "../interfaces/ITreasury.sol";

import "./SafeMath.sol";


library BLXMLibrary {
    using SafeMath for uint;

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'INSUFFICIENT_RESERVES');
        amountB = amountA.mul(reserveB) / reserveA;
    }
    
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

    event Mint(address indexed sender, uint amountBlxm, uint amountToken);
    event Burn(address indexed sender, uint amountBlxm, uint amountToken, uint rewardAmount, address indexed to);
    event AddRewards(address indexed sender, uint16 session, uint amountPerHours);
    event ArrangeFailedRewards(address indexed sender, uint32 startHour, uint32 endHour, uint amountPerHours);
    event UpdateRatio(address indexed sender, address token, uint ratio, uint blockNumberLast);


    function getRewardFactor(uint16 _days) external view returns (uint factor);
    function updateRewardFactor(uint16 lockedDays, uint factor) external returns (bool);

    function allPosition(address investor, uint idx) external view returns(address token, uint liquidity, uint extraLiquidity, uint32 startHour, uint32 endLocking);
    function allPositionLength(address investor) external view returns (uint);
    function calcRewards(address investor, uint idx) external view returns (uint amount, bool isLocked);
    
    function getTreasuryFields(address token) external view returns (uint32 syncHour, uint totalLiquidity, uint pendingRewards, uint32 initialHour, uint16 lastSession);
    function getDailyStatistics(address token, uint32 hourFromEpoch) external view returns (uint liquidityIn, uint liquidityOut, uint aggregatedRewards, uint32 next);
    function syncStatistics(address token) external;
    function hoursToSession(address token, uint32 hourFromEpoch) external view returns (uint16 session);
    function getPeriods(address token, uint16 session) external view returns (uint amountPerHours, uint32 startHour, uint32 endHour);

    function getRatio(address token) external view returns (uint ratio, uint blockNumberLast);
    function updateRatio(address token, uint ratio, uint interval) external;

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./interfaces/IBLXMTreasuryManager.sol";
import "./BLXMMultiOwnable.sol";

import "./interfaces/ITreasury.sol";


contract BLXMTreasuryManager is BLXMMultiOwnable, IBLXMTreasuryManager {

    // token => treasury
    mapping(address => address) internal treasurys;
    // rewards token or black list
    mapping(address => bool) internal exclude;


    function putTreasury(address token, address treasury) external override onlyOwner {
        _validateToken(token);
        BLXMLibrary.validateAddress(treasury);

        address oldTreasury = treasurys[token];
        treasurys[token] = treasury;
        emit TreasuryPut(msg.sender, oldTreasury, treasury, token);
    }

    function getTreasury(address token) public view override returns (address treasury) {
        _validateToken(token);
        BLXMLibrary.validateAddress(treasury = treasurys[token]);
    }

    function getReserves(address token) public view override returns (uint reserveBlxm, uint reserveToken) {
        (reserveBlxm, reserveToken,,,,) = ITreasury(getTreasury(token)).get_total_amounts();
    }

    function _withdraw(address treasury, uint rewards, uint liquidity, uint totalLiquidity, address to) internal returns (uint amountBlxm, uint amountToken) {
        (amountToken, amountBlxm) = ITreasury(treasury).get_tokens(rewards, liquidity, totalLiquidity, to);
    }

    function _notify(address treasury, uint amountBlxm, uint amountToken, address to) internal {
        ITreasury(treasury).add_liquidity(amountBlxm, amountToken, to);
    }

    function _validateToken(address token) internal view {
        require(!exclude[token], 'INVALID_TOKEN');
        BLXMLibrary.validateAddress(token);
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

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
     * This empty reserved space is put in place to allow future versions to add new
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


interface IBLXMTreasuryManager {

    event TreasuryPut(address indexed sender, address oldTreasury, address newTreasury, address indexed token);

    function putTreasury(address token, address treasury) external;
    function getTreasury(address token) external view returns (address treasury);
    function getReserves(address token) external view returns (uint reserveBlxm, uint reserveToken);
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface ITreasury {
    function get_total_amounts() external view returns (uint amount0, uint amount1, uint[] memory totalAmounts0, uint[] memory totalAmounts1, uint[] memory currentAmounts0, uint[] memory currentAmounts1);
    function get_tokens(uint reward, uint requestedLiquidity, uint totalLiquidityInLSC, address to) external returns (uint sentToken, uint sentBlxm);
    function add_liquidity(uint amountBlxm, uint amountToken, address to) external;
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