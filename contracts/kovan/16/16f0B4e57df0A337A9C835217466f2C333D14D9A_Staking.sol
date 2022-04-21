// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract Staking is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant SPONSOR = keccak256("SPONSOR");
    uint256 public constant PERCENTS_BASE = 100;
    uint256 public constant MULTIPLIER = 10**19;
    uint256 public constant YEAR = 365 days;

    IERC20 public immutable KON;
    uint256 public immutable deployTime;
    
    IERC20 public rewardToken;
    uint256 public maxPool = 20 * (10**6) * (10**18);
    uint256 public inactiveTokensInPool;
    uint256 public globalKoeffUSDTFW;
    uint256 public globalKoeffKONFW;
    uint256 public globalKoeffUSDTRW;
    uint256 public globalKoeffKONRW;
    uint256 public poolFullWeight;
    uint256 public poolReducedWeight;
    uint256 public penalty;
    uint256 public penaltyInKONAfterChange;
    uint256 public excessOfRewards;
    uint256 public capacity = 10;
    
    uint256[3] public percents = [15, 20, 25];
    uint256[3] public totalStaked;
    uint256[4] public updateIndexes;
    uint256[4] public lastUpdate;
    uint256[] public weight;
    DepositInfo[] public allDeposits;
    uint256 private _lock;

    mapping(address => uint256[]) public indexForUser;
    mapping(uint256 => uint256) public weightForDeposit;
    mapping(address => WhiteListInfo) public whiteListForUser;
    mapping(uint256 => RewardPool_3) public reward3Info;
    mapping(uint256 => uint256) public lockOwnersDeposits; 

    struct WhiteListInfo {
        uint256 index;
        uint256 enteredAt;
        uint256 amount;
        uint256 lockUpWL;
    }

    struct DepositInfo {
        Koeff varKoeff;
        address user;
        uint256 lockUp;
        uint256 sumInLock;
        uint256 enteredAt;
        uint256 pool;
        uint256 countHarvest;
        bool gotFixed;
    }

    struct Koeff {
        uint256 koeffBeforeDepositKON;
        uint256 koeffBeforeDepositUSDT;
        uint256 unreceivedRewardKON;
        uint256 unreceivedRewardUSDT;
        uint256 receivedRewardKON;
        uint256 receivedRewardUSDT;
    }

    struct RewardPool_3 {
        uint256 variableRewardTaken;
        uint256 part;
    }

    // to prevent too deep stack
    struct IntVars {
        uint256 rewardsUSDT;
        uint256 rewardsKON;
        uint256 amountPenalty;
        uint256 amountKON;
        uint256 amountUSDT;
    }

    event Deposit(address user, uint256 amount, uint256 lockUp, uint256 index);
    event Withdraw(address user, uint256 index);
    event Harvest(
        address user,
        uint256 amountKON,
        uint256 amountUSDT,
        uint256 index
    );
    event Reward(uint256 amount, uint256 time);

    modifier update() {
        updatePool();
        _;
    }

    modifier creator(uint256 index) {
        require(allDeposits[index].user == _msgSender(), "10");
        _;
    }

    modifier depositeIndex(uint256 index) {
        require(index < allDeposits.length, "0");
        _;
    }

    modifier nonReentrant() {
        require(_lock != 1, "1_");
        _lock = 1;
        _;
        _lock = 0;
    }

    constructor(
        address _kon,
        address _owner,
        address _sponsor
    ) {
        require(_kon != address(0) && _owner != address(0), "1");
        KON = IERC20(_kon);
        rewardToken = IERC20(_kon);
        weight.push(PERCENTS_BASE);
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(SPONSOR, _sponsor);
        deployTime = block.timestamp;
    }

    function indexes(address user) external view returns (uint256[] memory) {
        return indexForUser[user];
    }

    /**
     * @param _maxPool set new amount for the cap of the entire pool
     * @param _capacity set new amount for the capacity
     * @param _weight set new amount for the weight
     */
    function changeInternalVariables(
        uint256 _maxPool,
        uint256 _capacity,
        uint256 _weight
    ) external update onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_maxPool != maxPool) {
            require(_maxPool > 0 && _maxPool >= stakedSum(), "1");
            maxPool = _maxPool;
        }
        if (_capacity != capacity) {
            require(_capacity > 0, "2");
            capacity = _capacity;
        }
        if (_weight != weight[weight.length - 1]) {
            require(_weight <= PERCENTS_BASE, "3");
            weight.push(_weight);
        }
    }

    /**
     * @param reward amounts of reward for variable parts
     */
    function updateAmountsOfRewards(uint256 reward)
        external
        update
        onlyRole(SPONSOR)
        nonReentrant
    {
        require(reward > 0, "1");
        uint256 timestamp = block.timestamp;
        for (uint256 j = 0; j < 4; j += 1) {
            require(timestamp == lastUpdate[j], "2");
        }
        uint256 pool = stakedSum();
        require(pool > 0, "3");
        uint256 amount = reward;
        if (penalty > 0) {
            amount += penalty;
            penalty = 0;
        }
        uint256 rewardRW = (amount * poolReducedWeight) / pool;
        uint256 rewardFW = amount - rewardRW;
        if (poolFullWeight == 0 && rewardFW != 0) excessOfRewards += rewardFW;
        if (rewardToken == KON) {
            if (rewardFW > 0 && poolFullWeight != 0)
                globalKoeffKONFW += ((rewardFW * MULTIPLIER) / poolFullWeight);
            if (rewardRW > 0)
                globalKoeffKONRW += (rewardRW * MULTIPLIER) / poolReducedWeight;
        } else {
            if (rewardFW > 0 && poolFullWeight != 0)
                globalKoeffUSDTFW += (rewardFW * MULTIPLIER) / poolFullWeight;
            if (rewardRW > 0)
                globalKoeffUSDTRW +=
                    (rewardRW * MULTIPLIER) /
                    poolReducedWeight;
        }
        rewardToken.safeTransferFrom(_msgSender(), address(this), reward);
        emit Reward(reward, timestamp);
    }

    /**
     * @param usdt address of new token for rewards
     */
    function setNewRewardToken(address usdt)
        external
        update
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(usdt != address(0) && rewardToken == KON, "1");
        uint256 timestamp = block.timestamp;
        for (uint256 j = 0; j < 4; j += 1) {
            require(timestamp == lastUpdate[j], "2");
        }
        uint256 pool = stakedSum();
        if (penalty > 0 && pool > 0) {
            uint256 rewardRW = (penalty * poolReducedWeight) / pool;
            uint256 rewardFW = penalty - rewardRW;
            if (rewardFW > 0 && poolFullWeight != 0)
                globalKoeffKONFW += (rewardFW * MULTIPLIER) / poolFullWeight;
            if (rewardRW > 0)
                globalKoeffKONRW += (rewardRW * MULTIPLIER) / poolReducedWeight;
            penalty = 0;
        } else if(penalty > 0 && pool == 0) {
            KON.safeTransfer(_msgSender(), penalty);
            penalty = 0;
        }
        rewardToken = IERC20(usdt);
    }

    function getExcessToken()
        external
        update
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(penaltyInKONAfterChange > 0 || excessOfRewards > 0, "1");
        if (penaltyInKONAfterChange > 0) {
            KON.safeTransfer(_msgSender(), penaltyInKONAfterChange);
            penaltyInKONAfterChange = 0;
        }
        if (excessOfRewards > 0) {
            rewardToken.safeTransfer(_msgSender(), excessOfRewards);
            excessOfRewards = 0;
        }
    }

    /**
     * @param enteredAt start
     * @param amount deposits
     * @param addresses users
     * @param lockUp lockUp
     * @param isActualDeposit true if the element is deposit but not white list
     */
    function depositOrWLFromOwner(
        uint256[] memory enteredAt,
        uint256[] memory amount,
        address[] memory addresses,
        uint256[] memory lockUp,
        bool[] memory isActualDeposit
    ) external update onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 timestamp = block.timestamp;
        require((timestamp - deployTime) / 1 days <= 3, "0");
        uint256 len = addresses.length;
        require(
            len == amount.length &&
                len == lockUp.length &&
                len == enteredAt.length &&
                len == isActualDeposit.length,
            "1"
        );
        uint256 debt;
        uint256 previousEnteredAt_;
        address user;
        WhiteListInfo memory wl;
        Koeff memory koeff;
        for (uint256 i = 0; i < len; i += 1) {
            wl = WhiteListInfo(
                allDeposits.length,
                enteredAt[i],
                amount[i],
                lockUp[i]
            );
            user = addresses[i];
            require(wl.amount > 0, "2");
            require(wl.lockUpWL <= 2, "3");
            require(user != address(0), "4");
            require(
                timestamp >= wl.enteredAt && wl.enteredAt >= previousEnteredAt_,
                "5"
            );
            previousEnteredAt_ = wl.enteredAt;
            indexForUser[user].push(wl.index);
            weightForDeposit[wl.index] = 0;
            if (!isActualDeposit[i]) {
                whiteListForUser[user] = WhiteListInfo(
                    wl.index,
                    wl.enteredAt,
                    wl.amount,
                    wl.lockUpWL
                );
                koeff = Koeff(0, 0, 0, 0, 0, 0);
                wl = WhiteListInfo(0, 0, 0, 0);
            } else {
                koeff = Koeff(globalKoeffKONFW, globalKoeffUSDTFW, 0, 0, 0, 0);
                totalStaked[wl.lockUpWL] += wl.amount;
                poolFullWeight += wl.amount;
                debt += wl.amount;
            }
            allDeposits.push(
                DepositInfo(
                    koeff,
                    user,
                    wl.lockUpWL,
                    wl.amount,
                    wl.enteredAt,
                    0,
                    0,
                    false
                )
            );
        }

        if (debt > 0) KON.safeTransferFrom(_msgSender(), address(this), debt);
    }

    function setLocks(uint256[] memory lockPeriod, uint256[] memory index) external onlyRole(DEFAULT_ADMIN_ROLE)  { 
        require((block.timestamp - deployTime) / 1 days <= 3, "0");
        uint256 len = index.length;
        for (uint256 i = 0; i < len; i += 1) {
            lockOwnersDeposits[index[i]] = lockPeriod[i];
        }
    }

    /**
     * @param amount for deposit
     * @param lockUp for deposit
     */
    function deposit(uint256 amount, uint256 lockUp)
        external
        update
        nonReentrant
    {
        require(amount > 0, "1");
        require(lockUp < 3, "2");
        require(stakedSum() + amount <= maxPool, "3");
        address user = _msgSender();
        uint256 depLen = allDeposits.length;
        uint256 weiLen = weight.length;
        uint256 timestamp = block.timestamp;
        uint256 globKon;
        uint256 globUSDT;

        WhiteListInfo memory whiteList_ = whiteListForUser[user];
        if (
            whiteList_.amount == amount &&
            whiteList_.lockUpWL == lockUp &&
            (timestamp - deployTime) / 14 days < 1
        ) {
            timestamp = whiteList_.enteredAt;
            depLen = whiteList_.index;
            weightForDeposit[depLen] = 0;
        } else {
            weightForDeposit[depLen] = weiLen - 1;
        }

        if (weight[weightForDeposit[depLen]] == PERCENTS_BASE) {
            poolFullWeight += amount;
            globKon = globalKoeffKONFW;
            globUSDT = globalKoeffUSDTFW;
        } else {
            poolReducedWeight += ((amount * weight[weiLen - 1]) /
                PERCENTS_BASE);
            globKon = globalKoeffKONRW;
            globUSDT = globalKoeffUSDTRW;
        }

        totalStaked[lockUp] += amount;

        DepositInfo memory dep = DepositInfo(
            Koeff(globKon, globUSDT, 0, 0, 0, 0),
            user,
            lockUp,
            amount,
            timestamp,
            0,
            0,
            false
        );

        if (depLen == allDeposits.length) {
            indexForUser[user].push(depLen);
            allDeposits.push(dep);
        } else {
            allDeposits[depLen] = dep;
            delete whiteListForUser[user];
        }

        KON.safeTransferFrom(user, address(this), amount);
        emit Deposit(user, amount, lockUp, depLen);
    }

    /**
     * @param index for deposit
     */
    function harvest(uint256 index)
        public
        update
        depositeIndex(index)
        creator(index)
        nonReentrant
    {
        (uint256 kon, uint256 usdt) = _harvest(index);
        address user = _msgSender();
        _transfers(user, kon, usdt);
        emit Harvest(user, kon, usdt, index);
    }

    /**
     * @param index for lockUp
     */
    function withdraw(uint256 index)
        external
        update
        depositeIndex(index)
        creator(index)
        nonReentrant
    {
        DepositInfo storage stake = allDeposits[index];
        if(lockOwnersDeposits[index] != 0) {
            require(block.timestamp >= lockOwnersDeposits[index], "00");
        }
        require(stake.sumInLock > 0, "1");
        (uint256 year, uint256 months) = _amountOfYears(stake.enteredAt);
        IntVars memory vars;
        vars.rewardsKON = stake.sumInLock;

        if (year <= stake.lockUp) {
            uint256 rewKON;
            if (
                (stake.lockUp < 2 && year == stake.pool) ||
                (stake.lockUp == 2 && year == stake.pool)
            ) {
                vars.rewardsUSDT = stake.varKoeff.unreceivedRewardUSDT;
                rewKON = stake.varKoeff.unreceivedRewardKON;
                stake.varKoeff.receivedRewardKON += stake
                    .varKoeff
                    .unreceivedRewardKON;
                stake.varKoeff.receivedRewardUSDT += stake
                    .varKoeff
                    .unreceivedRewardUSDT;
                (vars.amountKON, vars.amountUSDT) = varPart(index);
            } else {
                (rewKON, vars.rewardsUSDT) = varPart(index);
            }

            vars.rewardsKON += currentFixedPart(index);
            vars.amountPenalty = fixedPart(index) / 2;

            vars.rewardsKON -= vars.amountPenalty;
            vars.rewardsKON += rewKON;

            if (rewardToken == KON) {
                penalty += vars.amountKON;
                penalty += vars.amountPenalty;
            } else {
                penaltyInKONAfterChange += vars.amountKON;
                penaltyInKONAfterChange += vars.amountPenalty;
                penalty += vars.amountUSDT;
            }
        } else if (
            (!stake.gotFixed &&
                (stake.lockUp < 2 ||
                    months >= reward3Info[index].variableRewardTaken))
        ) {
            (vars.amountKON, vars.rewardsUSDT) = _harvest(index);
            vars.rewardsKON += vars.amountKON;
        }

        if (
            (stake.lockUp == 2 && stake.pool != 4) ||
            (stake.lockUp < 2 && stake.pool < stake.lockUp + 1)
        ) _updateTotalStaked(stake.sumInLock, stake.lockUp, index);
        else inactiveTokensInPool -= stake.sumInLock;

        _transfers(stake.user, vars.rewardsKON, vars.rewardsUSDT);

        emit Withdraw(stake.user, index);

        delete allDeposits[index];
    }

    function stakedSum() public view returns (uint256 amount) {
        for (uint256 i = 0; i < 3; i += 1) {
            amount += totalStaked[i];
        }
    }

    /**
     * @dev calculate fixed part for now
     * @param index index of deposit
     */
    function currentFixedPart(uint256 index)
        public
        view
        returns (uint256 amount)
    {
        DepositInfo memory stake = allDeposits[index];
        (uint256 year, ) = _amountOfYears(stake.enteredAt);
        uint256 i;
        for (i; i < year && i <= stake.lockUp; i += 1) {
            amount += percents[i];
        }
        amount += (amount * stake.sumInLock) / PERCENTS_BASE; // фикс награда
        if (year < stake.lockUp + 1)
            amount += (((15 + (5 * i)) *
                stake.sumInLock * //
                (block.timestamp - (stake.enteredAt + YEAR * year))) / //
                (PERCENTS_BASE * YEAR));
    }

    /**
     * @dev calculate fixed part for stake for the entire period
     * @param index index of deposit
     */
    function fixedPart(uint256 index) public view returns (uint256 amount) {
        DepositInfo memory stake = allDeposits[index];
        for (uint256 i = 0; i < 3 && i <= stake.lockUp; i += 1) {
            amount += percents[i];
        }
        amount = (amount * stake.sumInLock) / PERCENTS_BASE;
    }

    /**
     * @dev calculate var part for now
     * @param index for deposit
     */
    function varPart(uint256 index)
        public
        view
        returns (uint256 inKON, uint256 inUSDT)
    {
        DepositInfo memory stake = allDeposits[index];
        uint256 weight_ = weight[weightForDeposit[index]];
        if (
            (stake.lockUp < 2 && stake.pool != stake.lockUp + 1) ||
            (stake.lockUp == 2 && stake.pool != 4)
        ) {
            if (weight_ == PERCENTS_BASE) {
                inKON = ((stake.sumInLock *
                    (globalKoeffKONFW - stake.varKoeff.koeffBeforeDepositKON)) /
                    MULTIPLIER -
                    stake.varKoeff.receivedRewardKON);
                if (globalKoeffUSDTFW != 0)
                    inUSDT = ((stake.sumInLock *
                        (globalKoeffUSDTFW -
                            stake.varKoeff.koeffBeforeDepositUSDT)) /
                        MULTIPLIER -
                        stake.varKoeff.receivedRewardUSDT);
            } else {
                uint256 amount = (stake.sumInLock * weight_) / PERCENTS_BASE;
                inKON = ((amount *
                    (globalKoeffKONRW - stake.varKoeff.koeffBeforeDepositKON)) /
                    MULTIPLIER -
                    stake.varKoeff.receivedRewardKON);
                if (globalKoeffUSDTRW != 0)
                    inUSDT = ((amount *
                        (globalKoeffUSDTRW -
                            stake.varKoeff.koeffBeforeDepositUSDT)) /
                        MULTIPLIER -
                        stake.varKoeff.receivedRewardUSDT);
            }
        } else
            return (
                stake.varKoeff.unreceivedRewardKON,
                stake.varKoeff.unreceivedRewardUSDT
            );
    }

    function updatePool() public {
        uint256 len = allDeposits.length;
        uint256 year;
        DepositInfo storage stake;

        uint256 i;
        uint256 limit;
        for (uint256 j = 0; j < 4; j += 1) {
            i = updateIndexes[j];
            limit = (i + capacity > len) ? len : i + capacity;
            for (i; i < limit; i += 1) {
                stake = allDeposits[i];
                (year, ) = _amountOfYears(stake.enteredAt);
                if (year > j) {
                    if (
                        stake.sumInLock > 0 &&
                        ((stake.lockUp < 2 && stake.pool <= stake.lockUp) ||
                            (stake.lockUp == 2 && stake.pool < 4))
                    ) {
                        (
                            stake.varKoeff.unreceivedRewardKON,
                            stake.varKoeff.unreceivedRewardUSDT
                        ) = varPart(i);
                        if (
                            (j < 2 && stake.lockUp == j) ||
                            (j == 3 && stake.lockUp == 2)
                        ) {
                            _updateTotalStaked(
                                stake.sumInLock,
                                stake.lockUp,
                                i
                            );
                            inactiveTokensInPool += stake.sumInLock;
                        }
                        stake.pool += 1;
                    }
                    updateIndexes[j] = i + 1;
                } else {
                    lastUpdate[j] = block.timestamp;
                    break;
                }
            }
            if (i == len) lastUpdate[j] = block.timestamp;
        }
    }

    function _amountOfYears(uint256 start)
        private
        view
        returns (uint256 amount, uint256 months)
    {
        amount = (block.timestamp - start) / YEAR;
        if (amount >= 3)
            months = (block.timestamp - (start + (3 * YEAR))) / 30 days;
    }

    function _transfers(
        address user,
        uint256 toTransferKON,
        uint256 toTransferUSDT
    ) private {
        require(toTransferKON > 0 || toTransferUSDT > 0, "01");
        if (toTransferKON > 0) {
            require(
                KON.balanceOf(address(this)) -
                    stakedSum() -
                    inactiveTokensInPool >=
                    toTransferKON,
                "02"
            );
            KON.safeTransfer(user, toTransferKON);
        }

        if (toTransferUSDT > 0) {
            require(
                rewardToken.balanceOf(address(this)) >= toTransferUSDT,
                "03"
            );
            rewardToken.safeTransfer(user, toTransferUSDT);
        }
    }

    function _updateTotalStaked(
        uint256 amount,
        uint256 lockUp,
        uint256 index
    ) private {
        totalStaked[lockUp] -= amount;
        if (weight[weightForDeposit[index]] == PERCENTS_BASE)
            poolFullWeight -= amount;
        else
            poolReducedWeight -= ((amount * weight[weightForDeposit[index]]) /
                PERCENTS_BASE);
    }

    function _harvest(uint256 index) private returns (uint256, uint256) {
        DepositInfo storage stake = allDeposits[index];
        RewardPool_3 storage reward = reward3Info[index];
        require(stake.sumInLock != 0, "1");
        (uint256 year, uint256 months) = _amountOfYears(stake.enteredAt);
        IntVars memory vars;
        if (stake.lockUp == 2 && year >= 3) {
            require(months >= reward.variableRewardTaken, "2");
            if (reward.part == 0) reward.part = fixedPart(index) / 6;
            if (reward.variableRewardTaken < 6) {
                if (months > 5) {
                    vars.amountKON =
                        reward.part *
                        (6 - reward.variableRewardTaken);
                } else
                    vars.amountKON =
                        reward.part *
                        (months + 1 - reward.variableRewardTaken);
            }
            reward.variableRewardTaken = months + 1;
        }
        if (
            (stake.lockUp < 2 &&
                (stake.pool >= stake.lockUp + 1 || year == stake.pool)) ||
            (stake.lockUp == 2 &&
                ((year < 3 && year == stake.pool) || stake.pool == 4))
        ) {
            vars.rewardsKON += stake.varKoeff.unreceivedRewardKON;
            vars.rewardsUSDT += stake.varKoeff.unreceivedRewardUSDT;
        } else {
            (vars.rewardsKON, vars.rewardsUSDT) = varPart(index);
            if (
                stake.lockUp < 2 ||
                (stake.lockUp == 2 && months > 11 && stake.pool != 4)
            ) stake.pool += 1;

            if (
                (stake.lockUp < 2 && stake.lockUp + 1 == stake.pool) ||
                (stake.lockUp == 2 && stake.pool == 4)
            ) {
                _updateTotalStaked(stake.sumInLock, stake.lockUp, index);
                inactiveTokensInPool += stake.sumInLock;
            }
        }
        if (
            stake.lockUp < 2 &&
            stake.pool >= stake.lockUp + 1 &&
            !stake.gotFixed
        ) {
            vars.amountKON = fixedPart(index);
            stake.gotFixed = true;
        }

        stake.varKoeff.receivedRewardKON += vars.rewardsKON;
        stake.varKoeff.receivedRewardUSDT += vars.rewardsUSDT;
        stake.varKoeff.unreceivedRewardKON = 0;
        stake.varKoeff.unreceivedRewardUSDT = 0;
        if (year <= stake.lockUp + 1) stake.countHarvest = year;
        else stake.countHarvest = stake.lockUp + 1;
        vars.rewardsKON += vars.amountKON;

        return (vars.rewardsKON, vars.rewardsUSDT);
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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