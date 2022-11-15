// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./StakingV2Storage.sol";
import "./common/ProxyAccessCommon.sol";

import "./libraries/SafeERC20.sol";
import {DSMath} from "./libraries/DSMath.sol";

import "./libraries/LibTreasury.sol";

import "./interfaces/IStaking.sol";
import "./interfaces/IStakingEvent.sol";

// import "hardhat/console.sol";

interface ILockTosV2 {

    function locksInfo(uint256 _lockId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
    function createLockByStaker(address user, uint256 _value, uint256 _unlockWeeks) external returns (uint256 lockId);
    function increaseAmountByStaker(address user, uint256 _lockId, uint256 _value) external;
    function increaseAmountUnlockTimeByStaker(address user, uint256 _lockId, uint256 _value, uint256 _unlockWeeks) external;
    function withdrawByStaker(address user, uint256 _lockId) external;
    function epochUnit() external view returns(uint256);
}

interface IITreasury {

    function enableStaking() external view returns (uint256);
    function requestTransfer(address _recipient, uint256 _amount)  external;
    function hasPermission(uint role, address account) external view returns (bool);
}

contract StakingV2 is
    StakingV2Storage,
    ProxyAccessCommon,
    DSMath,
    IStaking,
    IStakingEvent
{
    /* ========== DEPENDENCIES ========== */
    using SafeERC20 for IERC20;


    /// @dev Check if a function is used or not
    modifier onlyBonder() {
        require(IITreasury(treasury).hasPermission(uint(LibTreasury.STATUS.BONDER), msg.sender), "sender is not a bonder");
        _;
    }

    modifier nonBasicBond(uint256 stakeId) {
        require(!(connectId[stakeId] == 0 && allStakings[stakeId].marketId > 0), "basicBond");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor() {
    }


    /* ========== onlyPolicyOwner ========== */

    /// @inheritdoc IStaking
    function setEpochInfo(
        uint256 _length,
        uint256 _end
    )
        external override onlyProxyOwner
        nonZero(_length)
        nonZero(_end)
    {
        epoch.length_ = _length;
        epoch.end = _end;

        emit SetEpochInfo(_length, _end);
    }

    /// @inheritdoc IStaking
    function setAddressInfos(
        address _tos,
        address _lockTOS,
        address _treasury
    )
        external override onlyProxyOwner
        nonZeroAddress(_tos)
        nonZeroAddress(_lockTOS)
        nonZeroAddress(_treasury)
    {
        require(address(tos) != _tos || lockTOS != _lockTOS || treasury != _treasury, "same address");
        tos = IERC20(_tos);
        lockTOS = _lockTOS;
        treasury = _treasury;

        emit SetAddressInfos(_tos, _lockTOS, _treasury);
    }

    /// @inheritdoc IStaking
    function setRebasePerEpoch(uint256 _rebasePerEpoch) external override onlyProxyOwner {
        rebasePerEpoch = _rebasePerEpoch;

        emit SetRebasePerEpoch(_rebasePerEpoch);
    }


    /// @inheritdoc IStaking
    function setBasicBondPeriod(uint256 _period)
        external override onlyProxyOwner
        nonZero(_period)
    {
        require(basicBondPeriod != _period,"same period");
        basicBondPeriod = _period;

        emit SetBasicBondPeriod(_period);
    }

    /* ========== onlyBonder ========== */

    /// @inheritdoc IStaking
    function generateMarketId() public override onlyBonder returns (uint256) {
        return ++marketIdCounter;
    }

    /// @inheritdoc IStaking
    function stakeByBond(
        address to,
        uint256 _amount,
        uint256 _marketId,
        uint256 tosPrice
    )
        external override onlyBonder
        nonZeroAddress(to)
        nonZero(_amount)
        nonZero(_marketId)
        returns (uint256 stakeId)
    {
        _checkStakeId(to);

        stakeId = _addStakeId();
        _addUserStakeId(to, stakeId);

        rebaseIndex();

        uint256 ltos = _createStakeInfo(to, stakeId, _amount, block.timestamp + basicBondPeriod, _marketId);

        emit StakedByBond(to, _amount, ltos, _marketId, stakeId, tosPrice);
    }

    /// @inheritdoc IStaking
    function stakeGetStosByBond(
        address _to,
        uint256 _amount,
        uint256 _marketId,
        uint256 _periodWeeks,
        uint256 tosPrice
    )
        external override onlyBonder
        nonZeroAddress(_to)
        returns (uint256 stakeId)
    {
        require(_amount > 0 && _periodWeeks > 0 && _marketId > 0, "zero input");

        (, uint256 unlockTime) = getUnlockTime(lockTOS, block.timestamp, _periodWeeks) ;

        _checkStakeId(_to);
        stakeId = _addStakeId();
        _addUserStakeId(_to, stakeId);

        rebaseIndex();

        uint256 ltos = _createStakeInfo(_to, stakeId, _amount, unlockTime, _marketId);

        uint256 stosPrincipal = LibStaking.compound(_amount, rebasePerEpoch, (unlockTime - block.timestamp) / epoch.length_);
        uint256 stosId = ILockTosV2(lockTOS).createLockByStaker(_to, stosPrincipal, _periodWeeks);
        require(stosId > 0, "zero stosId");

        connectId[stakeId] = stosId;

        emit StakedGetStosByBond(_to, _amount, ltos, _periodWeeks, _marketId, stakeId, stosId, tosPrice, stosPrincipal);
    }

    /* ========== Anyone can execute ========== */

    /// @inheritdoc IStaking
    function stake(
        uint256 _amount
    )   external override
        nonZero(_amount)
        returns (uint256 stakeId)
    {
        _checkStakeId(msg.sender);
        stakeId = userStakings[msg.sender][1]; // 0번은 더미, 1번은 기간없는 순수 스테이킹

        rebaseIndex();

        tos.safeTransferFrom(msg.sender, treasury, _amount);

        uint256 ltos = getTosToLtos(_amount);

        if (allStakings[stakeId].staker == msg.sender) {
            LibStaking.UserBalance storage _stakeInfo = allStakings[stakeId];
            _stakeInfo.deposit += _amount;
            _stakeInfo.ltos += ltos;

        } else {
            allStakings[stakeId] = LibStaking.UserBalance({
                staker: msg.sender,
                deposit: _amount,
                ltos: ltos,
                endTime: block.timestamp + 1,
                marketId: 0
            });
        }

        stakingPrincipal += _amount;
        totalLtos += ltos;

        emit Staked(msg.sender, _amount, stakeId);
    }

    /// @inheritdoc IStaking
    function stakeGetStos(
        uint256 _amount,
        uint256 _periodWeeks
    )
        external override
        nonZero(_amount)
        nonZero(_periodWeeks)
        nonZero(rebasePerEpoch)
        returns (uint256 stakeId)
    {
        (, uint256 unlockTime) = getUnlockTime(lockTOS, block.timestamp, _periodWeeks) ;
        // require(unlockTime > 0, "zero unlockTime");

        _checkStakeId(msg.sender);
        stakeId = _addStakeId();
        _addUserStakeId(msg.sender, stakeId);

        rebaseIndex();

        tos.safeTransferFrom(msg.sender, treasury, _amount);

        _createStakeInfo(msg.sender, stakeId, _amount, unlockTime, 0);

        uint256 stosPrincipal = LibStaking.compound(_amount, rebasePerEpoch, (unlockTime - block.timestamp) / epoch.length_);
        uint256 stosId = ILockTosV2(lockTOS).createLockByStaker(msg.sender, stosPrincipal, _periodWeeks);
        require(stosId > 0, "zero stosId");

        connectId[stakeId] = stosId;

        emit StakedGetStos(msg.sender, _amount, _periodWeeks, stakeId, stosId, stosPrincipal);
    }


    /// @inheritdoc IStaking
    function increaseAmountForSimpleStake(
        uint256 _stakeId,
        uint256 _amount
    )   external override
        nonZero(_stakeId)
        nonZero(_amount)
    {
        LibStaking.UserBalance storage _stakeInfo = allStakings[_stakeId];

        require(_stakeInfo.staker == msg.sender, "caller is not staker");
        require(userStakingIndex[msg.sender][_stakeId] == 1, "it's not simple staking product");
        rebaseIndex();

        uint256 ltos = getTosToLtos(_amount);
        _stakeInfo.deposit += _amount;
        _stakeInfo.ltos += ltos;
        stakingPrincipal += _amount;
        totalLtos += ltos;

        tos.safeTransferFrom(msg.sender, treasury, _amount);

        emit IncreasedAmountForSimpleStake(msg.sender, _amount, _stakeId);
    }

    function _closeEndTimeOfLockTos(address sender, uint256 _stakeId, uint256 lockId, uint256 _endTime) internal {
        (, uint256 end, ) = ILockTosV2(lockTOS).locksInfo(lockId);
        require(end < block.timestamp && _endTime < block.timestamp, "lock end time has not passed");
        ILockTosV2(lockTOS).withdrawByStaker(sender, lockId);
        delete connectId[_stakeId];
    }

    /// @inheritdoc IStaking
    function resetStakeGetStosAfterLock(
        uint256 _stakeId,
        uint256 _addAmount,
        uint256 _periodWeeks
    )
        external override
    {
        require(_addAmount > 0 || _periodWeeks > 0, "all zero input");

        LibStaking.UserBalance storage _stakeInfo = allStakings[_stakeId];
        require(_stakeInfo.staker == msg.sender, "caller is not staker");
        require(userStakingIndex[msg.sender][_stakeId] > 1, "it's not for simple stake or empty.");

        uint256 lockId = connectId[_stakeId];
        if (lockId > 0) _closeEndTimeOfLockTos(msg.sender, _stakeId, lockId, _stakeInfo.endTime);
        else require(_stakeInfo.endTime < block.timestamp, "lock end time has not passed");

        (uint256 stosEpochUnit, uint256 unlockTime) = getUnlockTime(lockTOS, block.timestamp, _periodWeeks) ;

        rebaseIndex();

        if (_addAmount > 0)  tos.safeTransferFrom(msg.sender, treasury, _addAmount);

        //--
        uint256 stakedAmount = getLtosToTos(_stakeInfo.ltos);
        uint256 addLtos = getTosToLtos(_addAmount);

        uint256 profit = 0;
        if(stakedAmount > _stakeInfo.deposit) profit = stakedAmount - _stakeInfo.deposit;
        _stakeInfo.ltos += addLtos;
        if (_periodWeeks > 0) _stakeInfo.endTime = unlockTime;

        _stakeInfo.deposit = _stakeInfo.deposit + _addAmount + profit;
        stakingPrincipal = stakingPrincipal + _addAmount + profit;
        totalLtos += addLtos;
        //----

        uint256 stosId = 0;
        uint256 stosPrincipal = 0;
        uint256 stakeId = _stakeId;

        if (_periodWeeks > 0) {
            (stosId, stosPrincipal) = _createStos(stakeId, msg.sender, stakedAmount + _addAmount, _periodWeeks, stosEpochUnit);
            connectId[stakeId] = stosId;
        }

        emit ResetStakedGetStosAfterLock(msg.sender, _addAmount, 0, _periodWeeks, stakeId, stosId, stosPrincipal);
    }


    /// @inheritdoc IStaking
    function resetStakeGetStosAfterLock(
        uint256 _stakeId,
        uint256 _addTosAmount,
        uint256 _relockLtosAmount,
        uint256 _periodWeeks
    )
        external override
    {
        require(_addTosAmount > 0 || _relockLtosAmount > 0, "all zero input");

        uint256 lockId = connectId[_stakeId];

        LibStaking.UserBalance storage _stakeInfo = allStakings[_stakeId];

        require(_stakeInfo.staker == msg.sender, "caller is not staker");
        require(userStakingIndex[msg.sender][_stakeId] > 1, "it's not for simple stake or empty.");
        require(_relockLtosAmount <= _stakeInfo.ltos, "stakedAmount is insufficient.");

        if (lockId > 0)  _closeEndTimeOfLockTos(msg.sender, _stakeId, lockId, _stakeInfo.endTime);
        else require(_stakeInfo.endTime < block.timestamp, "lock end time has not passed");

        rebaseIndex();

        uint256 _claimTosAmount = 0;
        if (_relockLtosAmount < _stakeInfo.ltos) _claimTosAmount = getLtosToTos(_stakeInfo.ltos - _relockLtosAmount);

        (uint256 stosEpochUnit, uint256 unlockTime) = getUnlockTime(lockTOS, block.timestamp, _periodWeeks) ;
        if (_periodWeeks == 0)  unlockTime = _stakeInfo.endTime;

        if (_addTosAmount > 0)  tos.safeTransferFrom(msg.sender, treasury, _addTosAmount);

        //====
        uint256 addLtos = 0;
        uint256 relockTosAmount = 0;

        if (_addTosAmount > 0)  addLtos = getTosToLtos(_addTosAmount);
        if (_relockLtosAmount > 0)  relockTosAmount = getLtosToTos(_relockLtosAmount);

        totalLtos = totalLtos - _stakeInfo.ltos + _relockLtosAmount + addLtos;
        stakingPrincipal = stakingPrincipal - _stakeInfo.deposit + relockTosAmount + _addTosAmount;

        _stakeInfo.ltos = _relockLtosAmount + addLtos;
        _stakeInfo.deposit = relockTosAmount + _addTosAmount ;
        _stakeInfo.endTime = unlockTime;
        //===
        uint256 stosId = 0;
        uint256 stosPrincipal = 0;
        uint256 stakeId = _stakeId;

        if (_periodWeeks > 0) {
            (stosId, stosPrincipal) = _createStos(stakeId, msg.sender, _stakeInfo.deposit, _periodWeeks, stosEpochUnit);
            connectId[stakeId] = stosId;
        }

        if (_claimTosAmount > 0) IITreasury(treasury).requestTransfer(msg.sender, _claimTosAmount);

        emit ResetStakedGetStosAfterLock(msg.sender, _addTosAmount, _claimTosAmount, _periodWeeks, stakeId, stosId, stosPrincipal);
    }

    /// @inheritdoc IStaking
    function increaseBeforeEndOrNonEnd(
        uint256 _stakeId,
        uint256 _amount
    )
        external override
        nonZero(_stakeId)
        nonZero(_amount)
        nonBasicBond(_stakeId)
    {
        LibStaking.UserBalance storage _stakeInfo = allStakings[_stakeId];

        require(_stakeInfo.staker == msg.sender, "caller is not staker");

        rebaseIndex();

        tos.safeTransferFrom(msg.sender, treasury, _amount);

        uint256 ltos = getTosToLtos(_amount);
        _stakeInfo.deposit += _amount;
        _stakeInfo.ltos += ltos;
        stakingPrincipal += _amount;
        totalLtos += ltos;

        uint256 lockId = connectId[_stakeId];
        uint256 amountCompound = 0;
        if (userStakingIndex[msg.sender][_stakeId] > 1 && lockId > 0) {
            (, uint256 end, uint256 principal) = ILockTosV2(lockTOS).locksInfo(lockId);
            require(end > block.timestamp && _stakeInfo.endTime > block.timestamp, "lock end time has passed");

            uint256 n = (_stakeInfo.endTime - block.timestamp) / epoch.length_;
            if (n == 1) amountCompound = _amount * (1 ether + rebasePerEpoch) / 1e18;
            else if (n > 1) amountCompound = LibStaking.compound(_amount, rebasePerEpoch, n);
            else amountCompound = _amount;

            ILockTosV2(lockTOS).increaseAmountByStaker(msg.sender, lockId, amountCompound);
            amountCompound = principal + amountCompound;
        }
        emit IncreasedBeforeEndOrNonEnd(msg.sender, _amount, 0, _stakeId, lockId, amountCompound);
    }

    /// @inheritdoc IStaking
    function increaseBeforeEndOrNonEnd(
        uint256 _stakeId,
        uint256 _amount,
        uint256 _unlockWeeks
    )
        external override
        nonZero(_stakeId)
        nonBasicBond(_stakeId)
    {
        require(_amount > 0 || _unlockWeeks > 0, "zero _amount and _unlockWeeks");

        LibStaking.UserBalance storage _stakeInfo = allStakings[_stakeId];
        require(_stakeInfo.staker == msg.sender, "caller is not staker");

        if(_unlockWeeks > 0) require(userStakingIndex[msg.sender][_stakeId] > 1, "it's simple staking product, can't lock.");
        rebaseIndex();

        uint256 lockId = connectId[_stakeId];
        (uint256 stosEpochUnit, uint256 unlockTime) = getUnlockTime(lockTOS, block.timestamp, _unlockWeeks) ;

        // -------------
        if (_amount > 0) {
            tos.safeTransferFrom(msg.sender, treasury, _amount);

            uint256 ltos = getTosToLtos(_amount);
            _stakeInfo.deposit += _amount;
            _stakeInfo.ltos += ltos;
            stakingPrincipal += _amount;
            totalLtos += ltos;
        }

        // -------------
        uint256 stosPrincipal = 0;

        if (userStakingIndex[msg.sender][_stakeId] > 1 && lockId == 0 && _unlockWeeks > 0) {
            (connectId[_stakeId], stosPrincipal) = _createStos(_stakeId, msg.sender, _amount + getLtosToTos(remainedLtos(_stakeId)), _unlockWeeks, stosEpochUnit);
            _stakeInfo.endTime = unlockTime;

        } else if (userStakingIndex[msg.sender][_stakeId] > 1 && lockId > 0) {
            (, uint256 end, uint256 principalAmount) = ILockTosV2(lockTOS).locksInfo(lockId);
            require(end > block.timestamp && _stakeInfo.endTime > block.timestamp, "lock end time has passed");

            if (_unlockWeeks == 0) { // 물량만 늘릴때 이자도 같이 늘린다.
                uint256 n = (_stakeInfo.endTime - block.timestamp) / epoch.length_;
                uint256 amountCompound = LibStaking.compound(_amount, rebasePerEpoch, n);

                if (amountCompound > 0) {
                    stosPrincipal = principalAmount + amountCompound;
                    ILockTosV2(lockTOS).increaseAmountByStaker(msg.sender, lockId, amountCompound);
                }

            } else if (_unlockWeeks > 0) { // 기간만 들어날때는 물량도 같이 늘어난다고 본다. 이자때문에 .
                uint256 amountCompound1 = 0; // 기간종료후 이자부분
                uint256 amountCompound2 = 0; // 추가금액이 있을경우, 늘어나는 부분
                uint256 lockWeeks = _unlockWeeks;
                uint256 addAmount = _amount;

                if (lockWeeks > 0) {
                    amountCompound1 = LibStaking.compound(principalAmount, rebasePerEpoch, ((lockWeeks * stosEpochUnit) / epoch.length_));
                    amountCompound1 = amountCompound1 - principalAmount;
                }

                if (addAmount > 0) {
                    uint256 n2 = (end - block.timestamp  + (lockWeeks * stosEpochUnit)) / epoch.length_;
                    if (n2 > 0) amountCompound2 = LibStaking.compound(addAmount, rebasePerEpoch, n2);
                }
                stosPrincipal = principalAmount + amountCompound1 + amountCompound2;
                ILockTosV2(lockTOS).increaseAmountUnlockTimeByStaker(msg.sender, lockId, amountCompound1 + amountCompound2, lockWeeks);

                _stakeInfo.endTime += (lockWeeks * stosEpochUnit);
            }

        }
        emit IncreasedBeforeEndOrNonEnd(msg.sender, _amount, _unlockWeeks, _stakeId, lockId, stosPrincipal);
    }

    /// @inheritdoc IStaking
    function claimForSimpleType(
        uint256 _stakeId,
        uint256 claimLtos
    )
        external override
        nonZero(_stakeId)
        nonZero(claimLtos)
    {
        require(connectId[_stakeId] == 0, "this is for non-lock product.");

        LibStaking.UserBalance storage _stakeInfo = allStakings[_stakeId];

        require(_stakeInfo.staker == msg.sender, "caller is not staker");
        require(_stakeInfo.endTime < block.timestamp, "end time has not passed.");
        require(claimLtos <= _stakeInfo.ltos, "ltos is insufficient");

        rebaseIndex();
        uint256 stakedAmount = getLtosToTos(_stakeInfo.ltos);
        uint256 _claimAmount = getLtosToTos(claimLtos);

        uint256 profit = 0;
        if (stakedAmount > _stakeInfo.deposit) profit = stakedAmount - _stakeInfo.deposit;
        else if (stakedAmount < _stakeInfo.deposit && _stakeInfo.ltos == claimLtos) _claimAmount = _stakeInfo.deposit;

        _stakeInfo.ltos -= claimLtos;
        totalLtos -= claimLtos;
        _stakeInfo.deposit = _stakeInfo.deposit + profit - _claimAmount;
        stakingPrincipal = stakingPrincipal + profit - _claimAmount;

        IITreasury(treasury).requestTransfer(msg.sender, _claimAmount);

        emit ClaimedForNonLock(msg.sender, _claimAmount, _stakeId);
    }


    /// @inheritdoc IStaking
    function unstake(
        uint256 _stakeId
    )   public override
        nonZero(_stakeId)
    {
        LibStaking.UserBalance storage _stakeInfo = allStakings[_stakeId];

        require(_stakeInfo.staker == msg.sender, "caller is not staker.");
        require(_stakeInfo.endTime < block.timestamp, "end time hasn't passed.");

        rebaseIndex();

        uint256 amount = getLtosToTos(_stakeInfo.ltos);
        require(amount > 0, "zero claimable amount");

        if (amount < _stakeInfo.deposit) amount = _stakeInfo.deposit;

        stakingPrincipal -= _stakeInfo.deposit;
        totalLtos -= _stakeInfo.ltos;

        uint256 _userStakeIdIndex  = _deleteUserStakeId(msg.sender, _stakeId);
        _deleteStakeId(_stakeId, _userStakeIdIndex) ;

        if (connectId[_stakeId] > 0) {
            ILockTosV2(lockTOS).withdrawByStaker(msg.sender, connectId[_stakeId]);
            delete connectId[_stakeId];
        }

        IITreasury(treasury).requestTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount, _stakeId);
    }

    /// @inheritdoc IStaking
    function multiUnstake(
        uint256[] calldata _stakeIds
    ) external override {
        require(_stakeIds.length > 0, "no stakeIds");

        uint256 len = _stakeIds.length;
        for(uint256 i = 0; i < len; i++) {
            unstake(_stakeIds[i]);
        }
    }

    /// @inheritdoc IStaking
    function rebaseIndex() public override {

        if(epoch.end <= block.timestamp ) {

            uint256 epochNumber = 1; // if block.timestamp > epoch.end => we have to rebase at least once

            if ((block.timestamp - epoch.end) > epoch.length_){
                epochNumber = (block.timestamp - epoch.end) / epoch.length_ + 1;
            }

            epoch.end += (epoch.length_ * epochNumber);

            uint256 newIndex;

            if (epochNumber == 1)  newIndex = index_ * (1 ether + rebasePerEpoch) / 1e18;
            else newIndex = LibStaking.compound(index_, rebasePerEpoch, epochNumber) ;

            uint256 _runwayTos = runwayTos();

            uint256 oldIndex = index_;
            uint256 needTos = totalLtos * (newIndex - index_) / 1e18;

            if (needTos > _runwayTos) newIndex = oldIndex + (_runwayTos * 1e18 / totalLtos) ;

            if (newIndex > oldIndex){
                index_ = newIndex;
                emit Rebased(oldIndex, newIndex, totalLtos);
            }
        }
    }

    /* ========== VIEW ========== */

    /// @inheritdoc IStaking
    function remainedLtos(uint256 _stakeId) public override view returns (uint256) {
         return allStakings[_stakeId].ltos  ;
    }

    /// @inheritdoc IStaking
    function claimableLtos(
        uint256 _stakeId
    )
        external view override nonZero(_stakeId) returns (uint256)
    {
        if (allStakings[_stakeId].endTime < block.timestamp)
            return remainedLtos(_stakeId);
        else return 0;
    }


    /// @inheritdoc IStaking
    function getIndex() public view override returns(uint256){
        return index_;
    }

    /// @inheritdoc IStaking
    function possibleIndex() public view override returns (uint256) {
        uint256 possibleIndex_ = index_;
        if(epoch.end <= block.timestamp) {
            uint256 epochNumber = 1;
            if((block.timestamp - epoch.end) > epoch.length_) epochNumber = (block.timestamp - epoch.end) / epoch.length_+1;

            if(epochNumber == 1)  possibleIndex_ = possibleIndex_ * (1 ether + rebasePerEpoch) / 1e18;
            else possibleIndex_ = LibStaking.compound(index_, rebasePerEpoch, epochNumber) ;
            uint256 _runwayTos = runwayTos();
            uint256 needTos = totalLtos * (possibleIndex_ - index_) / 1e18;

            if(needTos > _runwayTos) possibleIndex_ = _runwayTos * 1e18 / totalLtos + index_;
        }
        return possibleIndex_;
    }

    /// @inheritdoc IStaking
    function stakingOf(address _addr)
        public
        override
        view
        returns (uint256[] memory)
    {
        return userStakings[_addr];
    }

    /// @inheritdoc IStaking
    function balanceOf(address _addr)
        public
        override
        view
        returns (uint256 balance)
    {
        uint256[] memory stakings = userStakings[_addr];
        if (stakings.length == 0) return 0;
        for (uint256 i = 0; i < stakings.length; ++i) {
            balance += remainedLtos(stakings[i]);
        }
    }


    /// @inheritdoc IStaking
    function secondsToNextEpoch() external override view returns (uint256) {
        if (epoch.end < block.timestamp) return 0;
        else return (epoch.end - block.timestamp);
    }

    /// @inheritdoc IStaking
    function runwayTosPossibleIndex() external override view returns (uint256) {
        uint256 treasuryAmount = IITreasury(treasury).enableStaking() ;
        uint256 debtTos =  getLtosToTosPossibleIndex(totalLtos);

        if (treasuryAmount < debtTos) return 0;
        else return (treasuryAmount - debtTos);
    }


    /// @inheritdoc IStaking
    function getTosToLtos(uint256 amount) public override view returns (uint256) {
        return (amount * 1e18) / index_;
    }

    /// @inheritdoc IStaking
    function getLtosToTos(uint256 ltos) public override view returns (uint256) {
        return (ltos * index_) / 1e18;
    }

    function getTosToLtosPossibleIndex(uint256 amount) public override view returns (uint256) {
        return (amount * 1e18) / possibleIndex();
    }

    /// @inheritdoc IStaking
    function getLtosToTosPossibleIndex(uint256 ltos) public override view returns (uint256) {
        return (ltos * possibleIndex()) / 1e18;
    }

    /// @inheritdoc IStaking
    function stakedOf(uint256 stakeId) external override view returns (uint256) {
        return getLtosToTosPossibleIndex(allStakings[stakeId].ltos);
    }

    /// @inheritdoc IStaking
    function stakedOfAll() external override view returns (uint256) {
        return getLtosToTosPossibleIndex(totalLtos);
    }

    /// @inheritdoc IStaking
    function stakeInfo(uint256 stakeId) public override view returns (
        address staker,
        uint256 deposit,
        uint256 ltos,
        uint256 endTime,
        uint256 marketId
    ) {
        LibStaking.UserBalance memory _stakeInfo = allStakings[stakeId];
        return (
            _stakeInfo.staker,
            _stakeInfo.deposit,
            _stakeInfo.ltos,
            _stakeInfo.endTime,
            _stakeInfo.marketId
        );
    }

    function runwayTos() public override view returns (uint256) {
        uint256 treasuryAmount = IITreasury(treasury).enableStaking() ;
        uint256 debtTos =  getLtosToTos(totalLtos);

        if (treasuryAmount < debtTos) return 0;
        else return (treasuryAmount - debtTos);
    }

    /* ========== internal ========== */


    function _stakeForSync(
        address to,
        uint256 amount,
        uint256 endTime,
        uint256 stosId
    )
        internal
        nonZero(amount)
        nonZero(endTime)
        returns (uint256 stakeId)
    {
        _checkStakeId(to);
        stakeId = _addStakeId();
        _addUserStakeId(to, stakeId);
        _createStakeInfo(to, stakeId, amount, endTime, 0);
        connectId[stakeId] = stosId;
    }

    function _createStos(uint256 _stakeId, address _to, uint256 _amount, uint256 _periodWeeks, uint256 stosEpochUnit)
         internal ifFree returns (uint256 stosId, uint256 amountCompound)
    {
        amountCompound = LibStaking.compound(_amount, rebasePerEpoch, (_periodWeeks * stosEpochUnit / epoch.length_));
        require (amountCompound > 0, "zero compounded amount");

        stosId = ILockTosV2(lockTOS).createLockByStaker(_to, amountCompound, _periodWeeks);
        require(stosId > 0, "zero stosId");
    }

    function _createStakeInfo(
        address _addr,
        uint256 _stakeId,
        uint256 _amount,
        uint256 _unlockTime,
        uint256 _marketId
    ) internal ifFree returns (uint256){

        uint256 ltos = getTosToLtos(_amount);

        allStakings[_stakeId] = LibStaking.UserBalance({
                staker: _addr,
                deposit: _amount,
                ltos: ltos,
                endTime: _unlockTime,
                marketId: _marketId
            });

        stakingPrincipal += _amount;
        totalLtos += ltos;

        return ltos;
    }

    function _deleteStakeId(uint256 _stakeId, uint256 _userStakeIdIndex) internal {
        if (_userStakeIdIndex > 1)  delete allStakings[_stakeId];
        else if (_userStakeIdIndex == 1) {
            // 초기화
            LibStaking.UserBalance storage _stakeInfo = allStakings[_stakeId];
            _stakeInfo.staker = address(0);
            _stakeInfo.deposit = 0;
            _stakeInfo.ltos = 0;
            _stakeInfo.endTime = 0;
            _stakeInfo.marketId = 0;
        }
    }


    function _addUserStakeId(address to, uint256 _id) internal {
        userStakingIndex[to][_id] = userStakings[to].length;
        userStakings[to].push(_id);
    }


    function _deleteUserStakeId(address to, uint256 _id) internal  returns (uint256 curIndex){

        curIndex = userStakingIndex[to][_id];

        if (curIndex > 1 && curIndex < userStakings[to].length ) {
            if (curIndex < userStakings[to].length-1){
                uint256 lastId = userStakings[to][userStakings[to].length-1];
                userStakings[to][curIndex] = lastId;
                userStakingIndex[to][lastId] = curIndex;
            }
            userStakingIndex[to][_id] = 0;
            userStakings[to].pop();
        }
    }

    function _checkStakeId(address to) internal {
         if (userStakings[to].length == 0) {
            userStakings[to].push(0); // 0번때는 더미
            stakingIdCounter++;
            userStakingIndex[to][stakingIdCounter] = 1; // 첫번째가 기간없는 순수 스테이킹용 .
            userStakings[to].push(stakingIdCounter);
        }
    }

    function _addStakeId() internal returns(uint256) {
        return ++stakingIdCounter;
    }



    /* ========== onlyOwner ========== */

    /// @inheritdoc IStaking
    function syncStos(
        address[] calldata accounts,
        uint256[] calldata balances,
        uint256[] calldata period,
        uint256[] calldata tokenId
    )
        external
        override
        onlyOwner
    {
        require(accounts.length > 0, "zero length");
        require(accounts.length == balances.length, "wrong balance length");
        require(accounts.length == period.length, "wrong period length");
        require(accounts.length == tokenId.length, "wrong tokenId length");

        for (uint256 i = 0; i < accounts.length; i++ ) {
            _stakeForSync(accounts[i], balances[i], period[i], tokenId[i]);
        }
    }

    function getUnlockTime(address lockTos, uint256 start, uint256 _periodWeeks)
        public view returns (uint256 stosEpochUnit, uint256 unlockTime)
    {
        stosEpochUnit = ILockTosV2(lockTos).epochUnit();
        if (_periodWeeks > 0) {
            unlockTime = start + (_periodWeeks * stosEpochUnit);
            unlockTime = unlockTime / stosEpochUnit * stosEpochUnit;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./libraries/LibStaking.sol";

import "./interfaces/IERC20.sol";

contract StakingV2Storage {

    LibStaking.Epoch public epoch;

    IERC20 public tos;
    address public lockTOS;
    address public treasury;

    uint256 public index_;
    uint256 internal free = 1;
    uint256 public totalLtos;
    uint256 public stakingPrincipal;
    uint256 public rebasePerEpoch;
    uint256 public basicBondPeriod;
    uint256 public stakingIdCounter;
    uint256 public marketIdCounter;

    // 0 비어있는 더미, 1 기간없는 순수 토스 스테이킹
    mapping(address => uint256[]) public userStakings;

    //address - stakeId - 0
    mapping(address => mapping(uint256 => uint256)) public userStakingIndex;

    mapping(uint256 => LibStaking.UserBalance) public allStakings;

    // stakeId -sTOSid
    mapping(uint256 => uint256) public connectId;

    modifier nonZero(uint256 tokenId) {
        require(tokenId != 0, "Staking: zero vallue");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(
            account != address(0),
            "Staking: zero address"
        );
        _;
    }

    /// @dev Check if a function is used or not
    modifier ifFree {
        require(free == 1, "LockId is already in use");
        free = 0;
        _;
        free = 1;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessRoleCommon.sol";

contract ProxyAccessCommon is AccessRoleCommon, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender) || isProxyAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    modifier onlyProxyOwner() {
        require(isProxyAdmin(msg.sender), "Accessible: Caller is not an proxy admin");
        _;
    }

    modifier onlyPolicyOwner() {
        require(isPolicy(msg.sender), "Accessible: Caller is not an policy admin");
        _;
    }

    function addProxyAdmin(address _owner)
        external
        onlyProxyOwner
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function removeProxyAdmin()
        public virtual onlyProxyOwner
    {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function transferProxyAdmin(address newAdmin)
        external virtual
        onlyProxyOwner
    {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyProxyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    /// @dev remove admin
    function removeAdmin() public virtual onlyOwner {
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(ADMIN_ROLE, newAdmin);
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    function addPolicy(address _account) public virtual onlyProxyOwner {
        grantRole(POLICY_ROLE, _account);
    }

    function removePolicy() public virtual onlyPolicyOwner {
        renounceRole(POLICY_ROLE, msg.sender);
    }

    function deletePolicy(address _account) public virtual onlyProxyOwner {
        revokeRole(POLICY_ROLE, _account);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function isProxyAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isPolicy(address account) public view virtual returns (bool) {
        return hasRole(POLICY_ROLE, account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// https://github.com/dapphub/ds-math/blob/de45767/src/math.sol
/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wmul2(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / WAD;
    }

    function rmul2(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / RAY;
    }

    function wdiv2(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, WAD) / y;
    }

    function rdiv2(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, RAY) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //  x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //  floor[(n-1) / 2] = floor[n / 2].
    //
    function wpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : WAD;

        for (n /= 2; n != 0; n /= 2) {
            x = wmul(x, x);

            if (n % 2 != 0) {
                z = wmul(z, x);
            }
        }
    }

    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title LibTreasury
library LibTreasury
{

    enum STATUS {
        NONE,              //
        RESERVEDEPOSITOR,  // 트래저리에 예치할수있는 권한
        RESERVESPENDER,    // 트래저리에서 자산 사용할 수 있는 권한
        RESERVETOKEN,      // 트래저리에서 사용가능한 토큰
        RESERVEMANAGER,     // 트래저리 어드민 권한
        LIQUIDITYDEPOSITOR, // 트래저리에 유동성 권한
        LIQUIDITYTOKEN,     // 트래저리에 유동성 토큰으로 사용할 수 있는 토큰
        LIQUIDITYMANAGER,   // 트래저리에 유동성 제공 가능자
        REWARDMANAGER,       // 트래저리에 민트 사용 권한.
        BONDER,              // 본더
        STAKER                  // 스테이커
    }

    // 민트된 양에서 원금(토스 평가금)빼고,
    // 나머지에서 기관에 분배 정보 (기관주소, 남는금액에서 퍼센트)의 구조체
    struct Minting {
        address mintAddress;
        uint256 mintPercents;
    }

    function getStatus(uint role) external pure returns (STATUS _status) {
        if (role == uint(STATUS.RESERVEDEPOSITOR)) return  STATUS.RESERVEDEPOSITOR;
        else if (role == uint(STATUS.RESERVESPENDER)) return  STATUS.RESERVESPENDER;
        else if (role == uint(STATUS.RESERVETOKEN)) return  STATUS.RESERVETOKEN;
        else if (role == uint(STATUS.RESERVEMANAGER)) return  STATUS.RESERVEMANAGER;
        else if (role == uint(STATUS.LIQUIDITYDEPOSITOR)) return  STATUS.LIQUIDITYDEPOSITOR;
        else if (role == uint(STATUS.LIQUIDITYTOKEN)) return  STATUS.LIQUIDITYTOKEN;
        else if (role == uint(STATUS.LIQUIDITYMANAGER)) return  STATUS.LIQUIDITYMANAGER;
        else if (role == uint(STATUS.REWARDMANAGER)) return  STATUS.REWARDMANAGER;
        else if (role == uint(STATUS.BONDER)) return  STATUS.BONDER;
        else if (role == uint(STATUS.STAKER)) return  STATUS.STAKER;
        else   return  STATUS.NONE;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IStaking {


    /* ========== onlyPolicyOwner ========== */

    /// @dev              modify epoch data
    /// @param _length    epoch's length (sec)
    /// @param _end       epoch's end time (sec)
    function setEpochInfo(
        uint256 _length,
        uint256 _end
    ) external;

    /// @dev              set tosAddress, lockTOS, treasuryAddress
    /// @param _tos       tosAddress
    /// @param _lockTOS   lockTOSAddress
    /// @param _treasury  treausryAddress
    function setAddressInfos(
        address _tos,
        address _lockTOS,
        address _treasury
    ) external;

    /// @dev                    set setRebasePerEpoch
    /// @param _rebasePerEpoch  rate for rebase per epoch (eth uint)
    ///                         If input the 0.9 -> 900000000000000000
    function setRebasePerEpoch(
        uint256 _rebasePerEpoch
    ) external;


    /// @dev            set minimum bonding period
    /// @param _period  _period (seconds)
    function setBasicBondPeriod(uint256 _period) external ;


    /* ========== onlyOwner ========== */

    /// @dev             migration of existing lockTOS contract data
    /// @param accounts  array of account for sync
    /// @param balances  array of tos amount for sync
    /// @param period    array of end time for sync
    /// @param tokenId   array of locktos id for sync
    function syncStos(
        address[] memory accounts,
        uint256[] memory balances,
        uint256[] memory period,
        uint256[] memory tokenId
    ) external ;



    /* ========== onlyBonder ========== */


    /// @dev Increment and returns the market ID.
    function generateMarketId() external returns (uint256);

    /// @dev             TOS minted from bonding is automatically staked for the user, and user receives LTOS. Lock-up period is based on the basicBondPeriod
    /// @param to        user address
    /// @param _amount   TOS amount
    /// @param _marketId market id
    /// @param tosPrice  amount of TOS per 1 ETH
    /// @return stakeId  stake id
    function stakeByBond(
        address to,
        uint256 _amount,
        uint256 _marketId,
        uint256 tosPrice
    ) external returns (uint256 stakeId);



    /// @dev                TOS minted from bonding is automatically staked for the user, and user receives LTOS and sTOS.
    /// @param _to          user address
    /// @param _amount      TOS amount
    /// @param _marketId    market id
    /// @param _periodWeeks number of lockup weeks
    /// @param tosPrice     amount of TOS per 1 ETH
    /// @return stakeId     stake id
    function stakeGetStosByBond(
        address _to,
        uint256 _amount,
        uint256 _marketId,
        uint256 _periodWeeks,
        uint256 tosPrice
    ) external returns (uint256 stakeId);


    /* ========== Anyone can execute ========== */


    /// @dev            user can stake TOS for LTOS without lockup period
    /// @param _amount  TOS amount
    /// @return stakeId stake id
    function stake(
        uint256 _amount
    ) external  returns (uint256 stakeId);


    /// @dev                user can stake TOS for LTOS and sTOS with lockup period
    /// @param _amount      TOS amount
    /// @param _periodWeeks number of lockup weeks
    /// @return stakeId     stake id
    function stakeGetStos(
        uint256 _amount,
        uint256 _periodWeeks
    ) external  returns (uint256 stakeId);


    /// @dev            increase the tos amount in stakeId of the simple stake product (without lock, without marketId)
    /// @param _stakeId stake id
    /// @param _amount  TOS amount
    function increaseAmountForSimpleStake(
        uint256 _stakeId,
        uint256 _amount
    )   external;

    /// @dev                used to update the amount of staking after the lockup period is passed
    /// @param _stakeId     stake id
    /// @param _addTosAmount   additional TOS to be staked
    /// @param _relockLtosAmount amount of LTOS to relock
    /// @param _periodWeeks lockup period
    function resetStakeGetStosAfterLock(
        uint256 _stakeId,
        uint256 _addTosAmount,
        uint256 _relockLtosAmount,
        uint256 _periodWeeks
    ) external;

    /// @dev                used to update the amount of staking after the lockup period is passed
    /// @param _stakeId     stake id
    /// @param _addTosAmount   additional TOS to be staked
    /// @param _periodWeeks lockup period
    function resetStakeGetStosAfterLock(
        uint256 _stakeId,
        uint256 _addTosAmount,
        uint256 _periodWeeks
    ) external;


    /// @dev             used to update the amount of staking before the lockup period is not passed
    /// @param _stakeId  stake id
    /// @param _amount   additional TOS to be staked
    function increaseBeforeEndOrNonEnd(
        uint256 _stakeId,
        uint256 _amount
    ) external;


    /// @dev                used to update the amount of staking before the lockup period is not passed
    /// @param _stakeId     stake id
    /// @param _amount      additional TOS to be staked
    /// @param _unlockWeeks additional lockup period
    function increaseBeforeEndOrNonEnd(
        uint256 _stakeId,
        uint256 _amount,
        uint256 _unlockWeeks
    ) external;


    /// @dev             claiming LTOS from stakeId without sTOS
    /// @param _stakeId  stake id
    /// @param claimLtos amount of LTOS to claim
    function claimForSimpleType(
        uint256 _stakeId,
        uint256 claimLtos
    ) external;


    /// @dev             used to unstake a specific staking ID
    /// @param _stakeId  stake id
    function unstake(
        uint256 _stakeId
    ) external;

    /// @dev             used to unstake multiple staking IDs
    /// @param _stakeIds stake id
    function multiUnstake(
        uint256[] calldata _stakeIds
    ) external;


    /// @dev LTOS index adjustment. Apply compound interest to the LTOS index
    function rebaseIndex() external;

    /* ========== VIEW ========== */


    /// @dev             returns the amount of LTOS for a specific stakingId.
    /// @param _stakeId  stake id
    /// @return return   LTOS balance of stakingId
    function remainedLtos(uint256 _stakeId) external view returns (uint256) ;

    /// @dev             returns the claimable amount of LTOS for a specific staking ID.
    /// @param _stakeId  stake id
    /// @return return   claimable amount of LTOS
    function claimableLtos(uint256 _stakeId) external view returns (uint256);

    /// @dev returns the current LTOS index value
    function getIndex() external view returns(uint256) ;

    /// @dev returns the LTOS index value if rebase() is called
    function possibleIndex() external view returns (uint256);

    /// @dev           returns a list of stakingIds owned by a specific account
    /// @param _addr   user account
    /// @return return list of stakingIds owned by account
    function stakingOf(address _addr)
        external
        view
        returns (uint256[] memory);

    /// @dev            returns the staked LTOS amount of the user in TOS
    /// @param _addr    user account
    /// @return balance staked LTOS amount of the user in TOS
    function balanceOf(address _addr) external view returns (uint256 balance);

    /// @dev returns the time left until next rebase
    /// @return time
    function secondsToNextEpoch() external view returns (uint256);

    /// @dev        returns amount of TOS owned by Treasury that can be used for staking interest in the future (if rebase() is not called)
    /// @return TOS returns number of TOS owned by the treasury that is not owned by the foundation nor for LTOS
    function runwayTos() external view returns (uint256);


    /// @dev        returns amount of TOS owned by Treasury that can be used for staking interest in the future (if rebase() is called)
    /// @return TOS returns number of TOS owned by the treasury that is not owned by the foundation nor for LTOS
    function runwayTosPossibleIndex() external view returns (uint256);

    /// @dev           converts TOS amount to LTOS (if rebase() is not called)
    /// @param amount  TOS amount
    /// @return return LTOS amount
    function getTosToLtos(uint256 amount) external view returns (uint256);

    /// @dev           converts LTOS to TOS (if rebase() is not called)
    /// @param ltos    LTOS Amount
    /// @return return TOS Amount
    function getLtosToTos(uint256 ltos) external view returns (uint256);


    /// @dev           converts TOS amount to LTOS (if rebase() is called)
    /// @param amount  TOS Amount
    /// @return return LTOS Amount
    function getTosToLtosPossibleIndex(uint256 amount) external view returns (uint256);

    /// @dev           converts LTOS to TOS (if rebase() is called)
    /// @param ltos    LTOS Amount
    /// @return return TOS Amount
    function getLtosToTosPossibleIndex(uint256 ltos) external view returns (uint256);

    /// @dev           returns number of LTOS staked (converted to TOS) in stakeId
    /// @param stakeId stakeId
    function stakedOf(uint256 stakeId) external view returns (uint256);

    /// @dev returns the total number of LTOS staked (converted to TOS) by users
    function stakedOfAll() external view returns (uint256) ;

    /// @dev            detailed information of specific staking ID
    /// @param stakeId  stakeId
    function stakeInfo(uint256 stakeId) external view returns (
        address staker,
        uint256 deposit,
        uint256 LTOS,
        uint256 endTime,
        uint256 marketId
    );

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IStakingEvent{

    /// @dev                this event occurs when set epoch info
    /// @param length       epoch's length(seconds)
    /// @param end          epoch's end time(seconds)
    event SetEpochInfo(
        uint256 length,
        uint256 end
    );


    /// @dev                    this event occurs when set addresses
    /// @param tosAddress       tos address
    /// @param lockTOSAddress   lockTOS address
    /// @param treasuryAddress  treasury address
    event SetAddressInfos(
        address tosAddress,
        address lockTOSAddress,
        address treasuryAddress
    );

    /// @dev                     this event occurs when set rebasePerEpoch data
    /// @param rebasePerEpoch    rebase rate Per Epoch
    event SetRebasePerEpoch(
        uint256 rebasePerEpoch
    );

    /// @dev            this event occurs when set index
    /// @param index    index
    event SetIndex(
        uint256 index
    );

    /// @dev            this event occurs when set the default lockup period(second)
    /// @param period   the default lockup period(second) when bonding.
    event SetBasicBondPeriod(
        uint256 period
    );


    /// @dev            this event occurs when bonding without sTOS
    /// @param to       user address
    /// @param amount   TOS amount used for staking
    /// @param ltos     LTOS amount from staking
    /// @param marketId marketId
    /// @param stakeId  stakeId
    /// @param tosPrice amount of TOS per 1 ETH
    event StakedByBond(
        address to,
        uint256 amount,
        uint256 ltos,
        uint256 marketId,
        uint256 stakeId,
        uint256 tosPrice
    );

    /// @dev                 this event occurs when bonding with sTOS
    /// @param to            user address
    /// @param amount        TOS amount used for staking
    /// @param ltos          LTOS amount from staking
    /// @param periodWeeks   lock period
    /// @param marketId      marketId
    /// @param stakeId       stakeId
    /// @param stosId        sTOSId
    /// @param tosPrice      amount of TOS per 1 ETH
    /// @param stosPrincipal number of TOS used for sTOS calculation
    event StakedGetStosByBond(
        address to,
        uint256 amount,
        uint256 ltos,
        uint256 periodWeeks,
        uint256 marketId,
        uint256 stakeId,
        uint256 stosId,
        uint256 tosPrice,
        uint256 stosPrincipal
    );

    /// @dev           this event occurs when staking without sTOS
    /// @param to      user address
    /// @param amount  TOS amount used for staking
    /// @param stakeId stakeId
    event Staked(address to, uint256 amount, uint256 stakeId);

    /// @dev                 this event occurs when staking with sTOS
    /// @param to            user address
    /// @param amount        TOS amount used for staking
    /// @param periodWeeks   lock period
    /// @param stakeId       stakeId
    /// @param stosId        sTOSId
    /// @param stosPrincipal number of TOS used for sTOS calculation
    event StakedGetStos(
        address to,
        uint256 amount,
        uint256 periodWeeks,
        uint256 stakeId,
        uint256 stosId,
        uint256 stosPrincipal
    );

    /// @dev           this event occurs when additional TOS is used for staking for LTOS
    /// @param to      user address
    /// @param amount  additional TOS used for staking
    /// @param stakeId stakeId
    event IncreasedAmountForSimpleStake(address to, uint256 amount, uint256 stakeId);


    /// @dev                 this event occurs when staking amount or/and lockup period is updated after the lockup period is passed
    /// @param to            user address
    /// @param addAmount     additional TOS used for staking
    /// @param claimAmount   amount of LTOS to claim
    /// @param periodWeeks   lock period
    /// @param stakeId       stakeId
    /// @param stosId        sTOSId
    /// @param stosPrincipal number of TOS used for sTOS calculation
    event ResetStakedGetStosAfterLock(
        address to,
        uint256 addAmount,
        uint256 claimAmount,
        uint256 periodWeeks,
        uint256 stakeId,
        uint256 stosId,
        uint256 stosPrincipal
    );

    /// @dev                 this event occurs when staking amount or/and lockup period is updated before the lockup period is passed
    /// @param staker        user address
    /// @param amount        additional TOS used for staking
    /// @param unlockWeeks   lock period
    /// @param stakeId       stakeId
    /// @param stosId        sTOSId
    /// @param stosPrincipal number of TOS used for sTOS calculation
    event IncreasedBeforeEndOrNonEnd(
        address staker,
        uint256 amount,
        uint256 unlockWeeks,
        uint256 stakeId,
        uint256 stosId,
        uint256 stosPrincipal
    );

    /// @dev               this event occurs claim for non lock stakeId
    /// @param staker      user address
    /// @param claimAmount amount of LTOS to claim
    /// @param stakeId     stakeId
    event ClaimedForNonLock(address staker, uint256 claimAmount, uint256 stakeId);

    /// @dev           this event occurs when unstaking stakeId that has passed the lockup period
    /// @param staker  user address
    /// @param amount  amount of TOS given to the user
    /// @param stakeId stakeId
    event Unstaked(address staker, uint256 amount, uint256 stakeId);

    /// @dev              this event occurs when the LTOS index updated
    /// @param oldIndex   LTOS index before rebase() is called
    /// @param newIndex   LTOS index after rebase() is called
    /// @param totalLTOS  Total amount of LTOS
    event Rebased(uint256 oldIndex, uint256 newIndex, uint256 totalLTOS);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;
import "./ABDKMath64x64.sol";

interface IILockTosV2 {
    function epochUnit() external view returns(uint256);
}


/// @title LibStaking
library LibStaking
{
    struct Epoch {
        uint256 length_; // in seconds
        uint256 end; // timestamp
    }

    struct UserBalance {
        address staker;
        uint256 deposit;    //tos staking 양
        uint256 ltos;       //변환된 LTOS 양
        uint256 endTime;    //끝나는 endTime
        uint256 marketId;   //bondMarketId
    }

    function pow (int128 x, uint n) public pure returns (int128 r) {
        r = ABDKMath64x64.fromUInt (1);
        while (n > 0) {
            if (n % 2 == 1) {
                r = ABDKMath64x64.mul (r, x);
                n -= 1;
            } else {
                x = ABDKMath64x64.mul (x, x);
                n /= 2;
            }
        }
    }

    function compound (uint principal, uint ratio, uint n) public pure returns (uint) {
        return ABDKMath64x64.mulu (
                pow (
                ABDKMath64x64.add (
                    ABDKMath64x64.fromUInt (1),
                    ABDKMath64x64.divu (
                    ratio,
                    10**18)),
                n),
                principal);
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 * https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have.
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have.
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
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
pragma solidity ^0.8.0;

contract AccessRoleCommon {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant POLICY_ROLE = keccak256("POLICY_ROLE");
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