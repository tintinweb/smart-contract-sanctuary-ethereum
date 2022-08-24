// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IPublicSale2.sol";
import "../common/ProxyAccessCommon.sol";
import "./PublicSaleStorage.sol";

import "../libraries/LibPublicSale2.sol";

interface IIERC20Burnable {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external ;
}

interface IIWTON {
    function swapToTON(uint256 wtonAmount) external returns (bool);
    function swapFromTON(uint256 tonAmount) external returns (bool);
}

interface IIVestingPublicFundAction {
    function funding(uint256 amount) external;
}

contract PublicSale2 is
    PublicSaleStorage,
    ProxyAccessCommon,
    ReentrancyGuard,
    IPublicSale2
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bool public exchangeTOS;

    event AddedWhiteList(address indexed from, uint256 tier);
    event ExclusiveSaled(address indexed from, uint256 amount);
    event Deposited(address indexed from, uint256 amount);

    event Claimed(address indexed from, uint256 amount);
    event Withdrawal(address indexed from, uint256 amount);
    event DepositWithdrawal(address indexed from, uint256 amount, uint256 liquidityAmount);

    modifier nonZero(uint256 _value) {
        require(_value > 0, "PublicSale: zero");
        _;
    }

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "PublicSale: zero address");
        _;
    }

    modifier beforeStartAddWhiteTime() {
        require(
            startAddWhiteTime == 0 ||
                (startAddWhiteTime > 0 && block.timestamp < startAddWhiteTime),
            "PublicSale: not beforeStartAddWhiteTime"
        );
        _;
    }

    modifier beforeEndAddWhiteTime() {
        require(
            endAddWhiteTime == 0 ||
                (endAddWhiteTime > 0 && block.timestamp < endAddWhiteTime),
            "PublicSale: not beforeEndAddWhiteTime"
        );
        _;
    }

    modifier greaterThan(uint256 _value1, uint256 _value2) {
        require(_value1 > _value2, "PublicSale: non greaterThan");
        _;
    }

    modifier lessThan(uint256 _value1, uint256 _value2) {
        require(_value1 < _value2, "PublicSale: non less than");
        _;
    }

    function changeTONOwner(
        address _address
    )
        external
        override
        onlyOwner
    {
        getTokenOwner = _address;
    }

    function setAllsetting(
        uint256[8] calldata _Tier,
        uint256[6] calldata _amount,
        uint256[8] calldata _time,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimPercents
    )
        external
        override
        onlyOwner
        beforeStartAddWhiteTime
    {
        uint256 balance = saleToken.balanceOf(address(this));
        require((_amount[0] + _amount[1]) <= balance && 1 ether <= balance, "amount err");
        require(_time[6] < _claimTimes[0], "time err");
        require((deployTime + delayTime) < _time[0], "snapshot need later");
        require(_time[0] < _time[1], "whitelist before snapshot");
        require(_claimTimes.length > 0 &&  _claimTimes.length == _claimPercents.length, "need the claimSet");
        
        if(snapshot != 0) {
            require(isProxyAdmin(msg.sender), "only DAO can set");
        }

        setTier(
            _Tier[0], _Tier[1], _Tier[2], _Tier[3]
        );
        setTierPercents(
            _Tier[4], _Tier[5], _Tier[6], _Tier[7]
        );
        setAllAmount(
            _amount[0],
            _amount[1],
            _amount[2],
            _amount[3],
            _amount[4],
            _amount[5]
        );
        setExclusiveTime(
            _time[1],
            _time[2],
            _time[3],
            _time[4]
        );
        setOpenTime(
            _time[0],
            _time[5],
            _time[6]
        );
        setEachClaim(
            _time[7],
            _claimTimes,
            _claimPercents
        );
    }

    /// @inheritdoc IPublicSale2
    function setExclusiveTime(
        uint256 _startAddWhiteTime,
        uint256 _endAddWhiteTime,
        uint256 _startExclusiveTime,
        uint256 _endExclusiveTime
    )
        public
        override
        onlyOwner
        nonZero(_startAddWhiteTime)
        nonZero(_endAddWhiteTime)
        nonZero(_startExclusiveTime)
        nonZero(_endExclusiveTime)
        beforeStartAddWhiteTime
    {
        if(startAddWhiteTime != 0) {
            require(isProxyAdmin(msg.sender), "only DAO can set");
        }

        require(
            (_startAddWhiteTime < _endAddWhiteTime) &&
            (_endAddWhiteTime < _startExclusiveTime) &&
            (_startExclusiveTime < _endExclusiveTime),
            "PublicSale : Round1time err"
        );
        startAddWhiteTime = _startAddWhiteTime;
        endAddWhiteTime = _endAddWhiteTime;
        startExclusiveTime = _startExclusiveTime;
        endExclusiveTime = _endExclusiveTime;
    }

    /// @inheritdoc IPublicSale2
    function setOpenTime(
        uint256 _snapshot,
        uint256 _startDepositTime,
        uint256 _endDepositTime
    )
        public
        override
        onlyOwner
        nonZero(_snapshot)
        nonZero(_startDepositTime)
        nonZero(_endDepositTime)
        beforeStartAddWhiteTime
    {
         if(snapshot != 0) {
            require(isProxyAdmin(msg.sender), "only DAO can set");
        }

        require(
            (_startDepositTime < _endDepositTime),
            "PublicSale : Round2time err"
        );

        snapshot = _snapshot;
        startDepositTime = _startDepositTime;
        endDepositTime = _endDepositTime;
    }

    function setEachClaim(
        uint256 _claimCounts,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimPercents
    )
        public
        override
        onlyOwner
        beforeStartAddWhiteTime
    {
        if(totalClaimCounts != 0) {
            require(isProxyAdmin(msg.sender), "only DAO can set");
        }
        
        totalClaimCounts = _claimCounts;
        uint256 i = 0;
        uint256 y = 0;
        for (i = 0; i < _claimCounts; i++) {
            claimTimes.push(_claimTimes[i]);
            if (i != 0){
                require(claimTimes[i-1] < claimTimes[i], "PublicSale: claimtime err");
            }
            y = y + _claimPercents[i];
            claimPercents.push(y);
        }

        require(y == 100, "claimPercents err");
    }

    /// @inheritdoc IPublicSale2
    function setAllTier(
        uint256[4] calldata _tier,
        uint256[4] calldata _tierPercent
    ) external override onlyOwner {
        require(
            stanTier1 <= _tier[0] &&
            stanTier2 <= _tier[1] &&
            stanTier3 <= _tier[2] &&
            stanTier4 <= _tier[3],
            "tier set error"
        );
        setTier(
            _tier[0],
            _tier[1],
            _tier[2],
            _tier[3]
        );
        setTierPercents(
            _tierPercent[0],
            _tierPercent[1],
            _tierPercent[2],
            _tierPercent[3]
        );
    }

    /// @inheritdoc IPublicSale2
    function setTier(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    )
        public
        override
        onlyOwner
        nonZero(_tier1)
        nonZero(_tier2)
        nonZero(_tier3)
        nonZero(_tier4)
        beforeStartAddWhiteTime
    {
        if(tiers[1] != 0) {
            require(isProxyAdmin(msg.sender), "only DAO can set");
        }
        tiers[1] = _tier1;
        tiers[2] = _tier2;
        tiers[3] = _tier3;
        tiers[4] = _tier4;
    }

    /// @inheritdoc IPublicSale2
    function setTierPercents(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    )
        public
        override
        onlyOwner
        nonZero(_tier1)
        nonZero(_tier2)
        nonZero(_tier3)
        nonZero(_tier4)
        beforeStartAddWhiteTime
    {
        if(tiersPercents[1] != 0) {
            require(isProxyAdmin(msg.sender), "only DAO can set");
        }
        require(
            _tier1.add(_tier2).add(_tier3).add(_tier4) == 10000,
            "PublicSale: Sum should be 10000"
        );
        tiersPercents[1] = _tier1;
        tiersPercents[2] = _tier2;
        tiersPercents[3] = _tier3;
        tiersPercents[4] = _tier4;
    }

    /// @inheritdoc IPublicSale2
    function setAllAmount(
        uint256 _totalExpectSaleAmount,
        uint256 _totalExpectOpenSaleAmount,
        uint256 _saleTokenPrice,
        uint256 _payTokenPrice,
        uint256 _hardcapAmount,
        uint256 _changePercent
    ) 
        public
        override 
        onlyOwner
        beforeStartAddWhiteTime 
    {
        if(totalExpectSaleAmount != 0) {
            require(isProxyAdmin(msg.sender), "only DAO can set");
        }
        require(_changePercent <= maxPer && _changePercent >= minPer,"PublicSale: need to set min,max");
        
        totalExpectSaleAmount = _totalExpectSaleAmount;
        totalExpectOpenSaleAmount = _totalExpectOpenSaleAmount;
        saleTokenPrice = _saleTokenPrice;
        payTokenPrice = _payTokenPrice;
        hardCap = _hardcapAmount;
        changeTOS = _changePercent;
    }

    function getClaims() public view
        returns (
            uint256[] memory
        )
    {
        uint256 len = claimPercents.length;
        uint256[] memory _claimPercents = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            _claimPercents[i] = claimPercents[i];
        }
        return (_claimPercents);
    }

    /// @inheritdoc IPublicSale2
    function totalExpectOpenSaleAmountView()
        public
        view
        override
        returns(uint256)
    {
        if (block.timestamp < endExclusiveTime) return totalExpectOpenSaleAmount;
        else return totalExpectOpenSaleAmount.add(totalRound1NonSaleAmount());
    }

    /// @inheritdoc IPublicSale2
    function totalRound1NonSaleAmount()
        public
        view
        override
        returns(uint256)
    {
        return totalExpectSaleAmount.sub(totalExSaleAmount);
    }


    function _toRAY(uint256 v) internal pure returns (uint256) {
        return v * 10 ** 9;
    }

    function _toWAD(uint256 v) public override pure returns (uint256) {
        return v / 10 ** 9;
    }

    /// @inheritdoc IPublicSale2
    function calculSaleToken(uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        uint256 tokenSaleAmount =
            _amount.mul(payTokenPrice).div(saleTokenPrice);
        return tokenSaleAmount;
    }

    /// @inheritdoc IPublicSale2
    function calculPayToken(uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        uint256 tokenPayAmount = _amount.mul(saleTokenPrice).div(payTokenPrice);
        return tokenPayAmount;
    }

    /// @inheritdoc IPublicSale2
    function calculTier(address _address)
        public
        view
        override
        nonZeroAddress(address(sTOS))
        nonZero(tiers[1])
        nonZero(tiers[2])
        nonZero(tiers[3])
        nonZero(tiers[4])
        returns (uint256)
    {
        uint256 sTOSBalance = sTOS.balanceOfAt(_address, snapshot);
        uint256 tier;
        if (sTOSBalance >= tiers[1] && sTOSBalance < tiers[2]) {
            tier = 1;
        } else if (sTOSBalance >= tiers[2] && sTOSBalance < tiers[3]) {
            tier = 2;
        } else if (sTOSBalance >= tiers[3] && sTOSBalance < tiers[4]) {
            tier = 3;
        } else if (sTOSBalance >= tiers[4]) {
            tier = 4;
        } else if (sTOSBalance < tiers[1]) {
            tier = 0;
        }
        return tier;
    }

    /// @inheritdoc IPublicSale2
    function calculTierAmount(address _address)
        public
        view
        override
        returns (uint256)
    {
        LibPublicSale.UserInfoEx storage userEx = usersEx[_address];
        uint256 tier = calculTier(_address);
        if (userEx.join == true && tier > 0) {
            uint256 salePossible =
                totalExpectSaleAmount
                    .mul(tiersPercents[tier])
                    .div(tiersAccount[tier])
                    .div(10000);
            return salePossible;
        } else if (tier > 0) {
            uint256 tierAccount = tiersAccount[tier].add(1);
            uint256 salePossible =
                totalExpectSaleAmount
                    .mul(tiersPercents[tier])
                    .div(tierAccount)
                    .div(10000);
            return salePossible;
        } else {
            return 0;
        }
    }

    /// @inheritdoc IPublicSale2
    function calculOpenSaleAmount(address _account, uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        LibPublicSale.UserInfoOpen storage userOpen = usersOpen[_account];
        uint256 depositAmount = userOpen.depositAmount.add(_amount);
        uint256 openSalePossible =
            totalExpectOpenSaleAmountView().mul(depositAmount).div(
                totalDepositAmount.add(_amount)
            );
        return openSalePossible;
    }

    function currentRound() public view returns (uint256 round) {
        if (block.timestamp > claimTimes[totalClaimCounts-1]) {
            return totalClaimCounts;
        }
        for (uint256 i = 0; i < totalClaimCounts; i++) {
            if (block.timestamp < claimTimes[i]) {
                return i;
            }
        }
    }

    function calculClaimAmount(address _account, uint256 _round)
        public
        view
        override
        returns (uint256 _reward, uint256 _totalClaim, uint256 _refundAmount)
    {
        if (block.timestamp < startClaimTime) return (0, 0, 0);
        if (_round > totalClaimCounts) return (0, 0, 0);

        LibPublicSale.UserClaim storage userClaim = usersClaim[_account];
        (, uint256 realSaleAmount, uint256 refundAmount) = totalSaleUserAmount(_account);  

        if (realSaleAmount == 0 ) return (0, 0, 0);
        if (userClaim.claimAmount >= realSaleAmount) return (0, 0, 0);   

        uint256 round = currentRound();

        uint256 amount;
        if (totalClaimCounts == round && _round == 0) {
            amount = realSaleAmount - userClaim.claimAmount;
            return (amount, realSaleAmount, refundAmount);
        }

        if(_round == 0) {
            amount = realSaleAmount.mul(claimPercents[round.sub(1)]).div(100);
            amount = amount - userClaim.claimAmount;
            return (amount, realSaleAmount, refundAmount);
        } else if(_round == 1) {
            amount = realSaleAmount.mul(claimPercents[round.sub(1)]).div(100);
            return (amount, realSaleAmount, refundAmount);
        } else {
            uint256 amount1 = realSaleAmount.mul(claimPercents[round.sub(1)]).div(100);
            uint256 amount2 = realSaleAmount.mul(claimPercents[round.sub(2)]).div(100);
            amount = amount1.sub(amount2);
            return (amount, realSaleAmount, refundAmount);
        }
    }

    /// @inheritdoc IPublicSale2
    function totalSaleUserAmount(address user) public override view returns (uint256 _realPayAmount, uint256 _realSaleAmount, uint256 _refundAmount) {
        LibPublicSale.UserInfoEx storage userEx = usersEx[user];

        if (userEx.join) {
            (uint256 realPayAmount, uint256 realSaleAmount, uint256 refundAmount) = openSaleUserAmount(user);
            return ( realPayAmount.add(userEx.payAmount), realSaleAmount.add(userEx.saleAmount), refundAmount);
        } else {
            return openSaleUserAmount(user);
        }
    }

    /// @inheritdoc IPublicSale2
    function openSaleUserAmount(address user) public override view returns (uint256 _realPayAmount, uint256 _realSaleAmount, uint256 _refundAmount) {
        LibPublicSale.UserInfoOpen storage userOpen = usersOpen[user];

        if (!userOpen.join || userOpen.depositAmount == 0) return (0, 0, 0);

        uint256 openSalePossible = calculOpenSaleAmount(user, 0);
        uint256 realPayAmount = calculPayToken(openSalePossible);
        uint256 depositAmount = userOpen.depositAmount;
        uint256 realSaleAmount = 0;
        uint256 returnAmount = 0;

        if (realPayAmount < depositAmount) {
            returnAmount = depositAmount.sub(realPayAmount);
            realSaleAmount = calculSaleToken(realPayAmount);
        } else {
            realPayAmount = userOpen.depositAmount;
            realSaleAmount = calculSaleToken(depositAmount);
        }

        return (realPayAmount, realSaleAmount, returnAmount);
    }

    /// @inheritdoc IPublicSale2
    function totalOpenSaleAmount() public override view returns (uint256){
        uint256 _calculSaleToken = calculSaleToken(totalDepositAmount);
        uint256 _totalAmount = totalExpectOpenSaleAmountView();

        if (_calculSaleToken < _totalAmount) return _calculSaleToken;
        else return _totalAmount;
    }

    /// @inheritdoc IPublicSale2
    function totalOpenPurchasedAmount() public override view returns (uint256){
        uint256 _calculSaleToken = calculSaleToken(totalDepositAmount);
        uint256 _totalAmount = totalExpectOpenSaleAmountView();
        if (_calculSaleToken < _totalAmount) return totalDepositAmount;
        else return  calculPayToken(_totalAmount);
    }

    function totalWhitelists() external view returns (uint256) {
        return whitelists.length;
    }

    /// @inheritdoc IPublicSale2
    function addWhiteList() external override nonReentrant {
        require(
            block.timestamp >= startAddWhiteTime,
            "PublicSale: whitelistStartTime has not passed"
        );
        require(
            block.timestamp < endAddWhiteTime,
            "PublicSale: end the whitelistTime"
        );
        uint256 tier = calculTier(msg.sender);
        require(tier >= 1, "PublicSale: need to more sTOS");
        LibPublicSale.UserInfoEx storage userEx = usersEx[msg.sender];
        require(userEx.join != true, "PublicSale: already attended");

        whitelists.push(msg.sender);

        userEx.join = true;
        userEx.tier = tier;
        userEx.saleAmount = 0;
        tiersAccount[tier] = tiersAccount[tier].add(1);

        emit AddedWhiteList(msg.sender, tier);
    }

    function _decodeApproveData(
        bytes memory data
    ) public override pure returns (uint256 approveData) {
        assembly {
            approveData := mload(add(data, 0x20))
        }
    }

    function calculTONTransferAmount(
        uint256 _amount,
        address _sender
    )
        internal
        nonZero(_amount)
        nonZeroAddress(_sender)

    {
        uint256 tonAllowance = IERC20(getToken).allowance(_sender, address(this));
        uint256 tonBalance = IERC20(getToken).balanceOf(_sender);

        if (tonAllowance > tonBalance) {
            tonAllowance = tonBalance; //tonAllowance가 tonBlance보다 더 클때 문제가 된다.
        }
        if (tonAllowance < _amount) {
            uint256 needUserWton;
            uint256 needWton = _amount.sub(tonAllowance);
            needUserWton = _toRAY(needWton);
            require(IERC20(wton).allowance(_sender, address(this)) >= needUserWton, "PublicSale: wton exceeds allowance");
            require(IERC20(wton).balanceOf(_sender) >= needUserWton, "need more wton");
            IERC20(wton).safeTransferFrom(_sender,address(this),needUserWton);
            IIWTON(wton).swapToTON(needUserWton);
            require(tonAllowance >= _amount.sub(needWton), "PublicSale: ton exceeds allowance");
            if (_amount.sub(needWton) > 0) {
                IERC20(getToken).safeTransferFrom(_sender, address(this), _amount.sub(needWton));
            }
        } else {
            require(tonAllowance >= _amount && tonBalance >= _amount, "PublicSale: ton exceeds allowance");
            IERC20(getToken).safeTransferFrom(_sender, address(this), _amount);
        }

        if (block.timestamp < endExclusiveTime) {
            emit ExclusiveSaled(_sender, _amount);
        } else {
            emit Deposited(_sender, _amount);
        }
    }

    /// @inheritdoc IPublicSale2
    function exclusiveSale(
        address _sender,
        uint256 _amount
    )
        public
        override
        nonZero(_amount)
        nonZero(totalClaimCounts)
        nonReentrant
    {
        require(
            block.timestamp >= startExclusiveTime,
            "PublicSale: exclusiveStartTime has not passed"
        );
        require(
            block.timestamp < endExclusiveTime,
            "PublicSale: end the exclusiveTime"
        );
        LibPublicSale.UserInfoEx storage userEx = usersEx[_sender];
        require(userEx.join == true, "PublicSale: not registered in whitelist");
        uint256 tokenSaleAmount = calculSaleToken(_amount);
        uint256 salePossible = calculTierAmount(_sender);

        require(
            salePossible >= userEx.saleAmount.add(tokenSaleAmount),
            "PublicSale: just buy tier's allocated amount"
        );

        uint256 tier = calculTier(_sender);

        if(userEx.payAmount == 0) {
            totalRound1Users = totalRound1Users.add(1);
            totalUsers = totalUsers.add(1);
            tiersExAccount[tier] = tiersExAccount[tier].add(1);
        }

        userEx.payAmount = userEx.payAmount.add(_amount);
        userEx.saleAmount = userEx.saleAmount.add(tokenSaleAmount);

        totalExPurchasedAmount = totalExPurchasedAmount.add(_amount);
        totalExSaleAmount = totalExSaleAmount.add(tokenSaleAmount);

        calculTONTransferAmount(_amount, _sender);
    }

    /// @inheritdoc IPublicSale2
    function deposit(
        address _sender,
        uint256 _amount
    )
        public
        override
        nonReentrant
    {
        require(
            block.timestamp >= startDepositTime,
            "PublicSale: don't start depositTime"
        );
        require(
            block.timestamp < endDepositTime,
            "PublicSale: end the depositTime"
        );

        LibPublicSale.UserInfoOpen storage userOpen = usersOpen[_sender];

        if (!userOpen.join) {
            depositors.push(_sender);
            userOpen.join = true;

            totalRound2Users = totalRound2Users.add(1);
            LibPublicSale.UserInfoEx storage userEx = usersEx[_sender];
            if (userEx.payAmount == 0) totalUsers = totalUsers.add(1);
        }
        userOpen.depositAmount = userOpen.depositAmount.add(_amount);
        totalDepositAmount = totalDepositAmount.add(_amount);

        calculTONTransferAmount(_amount, _sender);
    }

    /// @inheritdoc IPublicSale2
    function claim() external override {
        require(
            block.timestamp >= claimTimes[0],
            "PublicSale: don't start claimTime"
        );
        LibPublicSale.UserInfoOpen storage userOpen = usersOpen[msg.sender];
        LibPublicSale.UserClaim storage userClaim = usersClaim[msg.sender];
        uint256 hardcapcut = hardcapCalcul();
        if (hardcapcut == 0) {
            require(userClaim.exec != true, "PublicSale: already getRefund");
            LibPublicSale.UserInfoEx storage userEx = usersEx[msg.sender];
            uint256 refundTON = userEx.payAmount.add(userOpen.depositAmount);
            userClaim.exec = true;
            IERC20(getToken).safeTransfer(msg.sender, refundTON);
        } else {
            (uint256 reward, uint256 realSaleAmount, uint256 refundAmount) = calculClaimAmount(msg.sender, 0);
            require(
                realSaleAmount > 0,
                "PublicSale: no purchase amount"
            );
            require(reward > 0, "PublicSale: no reward");
            require(
                realSaleAmount.sub(userClaim.claimAmount) >= reward,
                "PublicSale: already getAllreward"
            );
            require(
                saleToken.balanceOf(address(this)) >= reward,
                "PublicSale: dont have saleToken in pool"
            );

            userClaim.claimAmount = userClaim.claimAmount.add(reward);

            saleToken.safeTransfer(msg.sender, reward);

            if (!userClaim.exec && userOpen.join) {
                totalRound2UsersClaim = totalRound2UsersClaim.add(1);
                userClaim.exec = true;
            }

            if (refundAmount > 0 && userClaim.refundAmount == 0){
                require(refundAmount <= IERC20(getToken).balanceOf(address(this)), "PublicSale: dont have refund ton");
                userClaim.refundAmount = refundAmount;
                IERC20(getToken).safeTransfer(msg.sender, refundAmount);
            }

            emit Claimed(msg.sender, reward);
        }
    }

    function hardcapCalcul() public view returns (uint256){
        uint256 totalPurchaseTONamount = totalExPurchasedAmount.add(totalOpenPurchasedAmount());
        uint256 calculAmount;
        if (totalPurchaseTONamount >= hardCap) {
            return calculAmount = totalPurchaseTONamount.mul(changeTOS).div(100);
        } else {
            return 0;
        }
    }

    /// @inheritdoc IPublicSale2
    function depositWithdraw() external override {
        require(adminWithdraw != true && exchangeTOS == true,"PublicSale : need the exchangeWTONtoTOS");

        uint256 liquidityTON = hardcapCalcul();
        uint256 getAmount = totalExPurchasedAmount.add(totalOpenPurchasedAmount()).sub(liquidityTON);
        // if (totalRound2Users == totalRound2UsersClaim){
        //     getAmount = IERC20(getToken).balanceOf(address(this)).sub(liquidityTON);
        // } else {
        //     getAmount = totalExPurchasedAmount.add(totalOpenPurchasedAmount()).sub(liquidityTON).sub(1 ether);
        // }        
        require(getAmount <= IERC20(getToken).balanceOf(address(this)), "PublicSale: no token to receive");        

        adminWithdraw = true;

        uint256 burnAmount = totalExpectSaleAmount.add(totalExpectOpenSaleAmount).sub(totalOpenSaleAmount()).sub(totalExSaleAmount);
        IIERC20Burnable(address(saleToken)).burn(burnAmount);
        
        IERC20(getToken).approve(address(getTokenOwner), getAmount);
        IIVestingPublicFundAction(getTokenOwner).funding(getAmount);
        // IERC20(getToken).safeTransfer(getTokenOwner, getAmount);

        emit DepositWithdrawal(msg.sender, getAmount, liquidityTON);
    }

    function exchangeWTONtoTOS(
        uint256 amountIn,
        address poolAddress
    ) 
        external
        override
    {
        require(amountIn > 0, "zero input amount");
        require(block.timestamp > endDepositTime,"PublicSale: need to end the depositTime");

        uint256 liquidityTON = hardcapCalcul();
        require(liquidityTON > 0, "PublicSale: don't pass the hardCap");

        // IIUniswapV3Pool pool = IIUniswapV3Pool(LibPublicSale2.getPoolAddress());
        // require(address(pool) != address(0), "pool didn't exist");

        (uint160 sqrtPriceX96, int24 tick,,,,,) =  IIUniswapV3Pool(poolAddress).slot0();
        require(sqrtPriceX96 > 0, "pool is not initialized");

        int24 timeWeightedAverageTick = OracleLibrary.consult(poolAddress, 120);
        require(
            LibPublicSale2.acceptMinTick(timeWeightedAverageTick, 60, 8) <= tick
            && tick < LibPublicSale2.acceptMaxTick(timeWeightedAverageTick, 60, 8),
            "It's not allowed changed tick range."
        );

        (uint256 amountOutMinimum, , uint160 sqrtPriceLimitX96)
            = LibPublicSale2.limitPrameters(amountIn, poolAddress, wton, address(tos), 18);
        
        uint256 wtonAmount = IERC20(wton).balanceOf(address(this));
        if(wtonAmount == 0) {
            IIWTON(wton).swapFromTON(liquidityTON);
            exchangeTOS = true;
        } else {
            require(wtonAmount >= amountIn, "PublicSale : amountIn is too large");
        }

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: wton,
                tokenOut: address(tos),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            });
        uint256 amountOut = ISwapRouter(uniswapRouter).exactInputSingle(params);
        tos.safeTransfer(liquidityVaultAddress, amountOut);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IPublicSale2 {
    /// @dev set changeTONOwner
    function changeTONOwner(
        address _address
    ) external; 

    /// @dev set the allsetting
    /// @param _Tier _Tier[0~3] : set the sTOS Tier standard, _Tier[4~7] : set the Tier percents
    /// @param _amount _amount[0] : Round1 Sale Amount, _amount[1] : Round2 Sale Amount, _amount[2] : saleToken Price, _amount[3] : TON Price, _amount[4] : hardcap amount, _amount[5] : ton to tos %
    /// @param _time _time[0] : sTOS snapshot time, _time[1] : whitelist startTime, _time[2] : whitelist endTime, _time[3] : round1 sale startTime, _time[4] : round1 sale endTime, _time[5] : round2 deposit startTime, _time[6] : round2 deposit endTime, _time[7] : totalClaimCounts
    /// @param _claimTimes _claimTimes[] : claim time array
    /// @param _claimPercents _claimPercents[] : claim percents array (this is need sum 100)
    function setAllsetting(
        uint256[8] calldata _Tier,
        uint256[6] calldata _amount,
        uint256[8] calldata _time,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimPercents
    ) external;

    /// @dev set information related to exclusive sale
    /// @param _startAddWhiteTime start time of addwhitelist
    /// @param _endAddWhiteTime end time of addwhitelist
    /// @param _startExclusiveTime start time of exclusive sale
    /// @param _endExclusiveTime start time of exclusive sale
    function setExclusiveTime(
        uint256 _startAddWhiteTime,
        uint256 _endAddWhiteTime,
        uint256 _startExclusiveTime,
        uint256 _endExclusiveTime
    ) external;

    /// @dev set information related to open sale
    /// @param _snapshot _snapshot timestamp
    /// @param _startDepositTime start time of deposit
    /// @param _endDepositTime end time of deposit
    function setOpenTime(
        uint256 _snapshot,
        uint256 _startDepositTime,
        uint256 _endDepositTime
    ) external;

    /// @dev set information related to open sale
    /// @param _claimCounts totalClaimCounts from this contract
    /// @param _claimTimes claim time array
    /// @param _claimPercents claim percents array (this is need sum 100)
    function setEachClaim(
        uint256 _claimCounts,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimPercents
    ) external;

    /// @dev set information related to tier and tierPercents
    /// @param _tier[4] sTOS condition setting
    /// @param _tierPercent[4] tier proportion setting
    function setAllTier(
        uint256[4] calldata _tier,
        uint256[4] calldata _tierPercent
    ) external;

    /// @dev set information related to tier
    /// @param _tier1 tier1 condition of STOS hodings
    /// @param _tier2 tier2 condition of STOS hodings
    /// @param _tier3 tier3 condition of STOS hodings
    /// @param _tier4 tier4 condition of STOS hodings
    function setTier(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    ) external;

    /// @dev set information related to tier proportion for exclusive sale
    /// @param _tier1 tier1 proportion (If it is 6%, enter as 600 -> To record up to the 2nd decimal point)
    /// @param _tier2 tier2 proportion
    /// @param _tier3 tier3 proportion
    /// @param _tier4 tier4 proportion
    function setTierPercents(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    ) external;

    /// @dev set information related to saleAmount and tokenPrice
    /// @param _totalExpectSaleAmount expected amount of exclusive sale
    /// @param _totalExpectOpenSaleAmount expected amount of open sale
    /// @param _saleTokenPrice the sale token price
    /// @param _payTokenPrice  the funding(pay) token price
    /// @param _hardcapAmount the sale token price
    /// @param _changePercent  the funding(pay) token price
    function setAllAmount(
        uint256 _totalExpectSaleAmount,
        uint256 _totalExpectOpenSaleAmount,
        uint256 _saleTokenPrice,
        uint256 _payTokenPrice,
        uint256 _hardcapAmount,
        uint256 _changePercent
    ) external;

    /// @dev view totalExpectOpenSaleAmount
    function totalExpectOpenSaleAmountView()
        external
        view
        returns(uint256);

    /// @dev view totalRound1NonSaleAmount
    function totalRound1NonSaleAmount() 
        external 
        view 
        returns(uint256);

    /// @dev calculate the sale Token amount
    /// @param _amount th amount
    function calculSaleToken(uint256 _amount) external view returns (uint256);

    /// @dev calculate the pay Token amount
    /// @param _amount th amount
    function calculPayToken(uint256 _amount) external view returns (uint256);

    /// @dev calculate the tier
    /// @param _address user address
    function calculTier(address _address) external view returns (uint256);

    /// @dev calculate the tier's amount
    /// @param _address user address
    function calculTierAmount(address _address) external view returns (uint256);

    /// @dev calculate the open sale amount
    /// @param _account user address
    /// @param _amount  amount
    function calculOpenSaleAmount(address _account, uint256 _amount)
        external
        view
        returns (uint256);

    /// @dev calculate the open sale amount
    /// @param _account user address
    function calculClaimAmount(address _account, uint256 _period)
        external
        view
        returns (uint256 _reward, uint256 _totalClaim, uint256 _refundAmount);


    /// @dev view totalSaleUserAmount
    function totalSaleUserAmount(address user) 
        external 
        view 
        returns (uint256 _realPayAmount, uint256 _realSaleAmount, uint256 _refundAmount);

    /// @dev view openSaleUserAmount
    function openSaleUserAmount(address user) 
        external 
        view 
        returns (uint256 _realPayAmount, uint256 _realSaleAmount, uint256 _refundAmount);
    
    /// @dev view totalOpenSaleAmount
    function totalOpenSaleAmount() 
        external 
        view 
        returns (uint256);

    /// @dev view totalOpenPurchasedAmount
    function totalOpenPurchasedAmount() 
        external
        view 
        returns (uint256);

    /// @dev execute add whitelist
    function addWhiteList() external;

    /// @dev execute exclusive sale
    /// @param _sender user address
    /// @param _amount  amount
    function exclusiveSale(address _sender,uint256 _amount) external;

    /// @dev execute deposit
    /// @param _sender user address
    /// @param _amount  amount
    function deposit(address _sender,uint256 _amount) external;

    /// @dev execute the claim
    function claim() external;

    /// @dev execute the depositWithdraw
    function depositWithdraw() external;

    /// @dev execute the exchangeWTONtoTOS
    function exchangeWTONtoTOS(
        uint256 amountIn,
        address poolAddress
    ) 
        external;

    function _decodeApproveData(
        bytes memory data
    ) external pure returns (uint256 approveData);

    function _toWAD(uint256 v) external pure returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
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
        grantRole(PROJECT_ADMIN_ROLE, account);
    }

    /// @dev remove admin
    function removeAdmin() public virtual onlyOwner {
        renounceRole(PROJECT_ADMIN_ROLE, msg.sender);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(PROJECT_ADMIN_ROLE, newAdmin);
        renounceRole(PROJECT_ADMIN_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(PROJECT_ADMIN_ROLE, account);
    }

    function isProxyAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILockTOS.sol";
import "../libraries/LibPublicSale.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract PublicSaleStorage  {
    /// @dev flag for pause proxy
    bool public pauseProxy;

    uint256 public snapshot = 0;
    uint256 public deployTime;              //contract 배포된 시간
    uint256 public delayTime;               //contract와 snapshot사이 시간

    uint256 public startAddWhiteTime = 0;
    uint256 public endAddWhiteTime = 0;
    uint256 public startExclusiveTime = 0;
    uint256 public endExclusiveTime = 0;

    uint256 public startDepositTime = 0;        //청약 시작시간
    uint256 public endDepositTime = 0;          //청약 끝시간

    uint256 public startClaimTime = 0;

    uint256 public totalUsers = 0;              //전체 세일 참여자 (라운드1,라운드2 포함, 유니크)
    uint256 public totalRound1Users = 0;         //라운드 1 참여자
    uint256 public totalRound2Users = 0;         //라운드 2 참여자
    uint256 public totalRound2UsersClaim = 0;    //라운드 2 참여자중 claim한사람

    uint256 public totalExSaleAmount = 0;       //총 exclu 실제 판매토큰 양 (exclusive)
    uint256 public totalExPurchasedAmount = 0;  //총 지불토큰 받은 양 (exclusive)

    uint256 public totalDepositAmount;          //총 청약 한 양 (openSale)

    uint256 public totalExpectSaleAmount;       //예정된 판매토큰 양 (exclusive)
    uint256 public totalExpectOpenSaleAmount;   //예정된 판매 토큰량 (opensale)

    uint256 public saleTokenPrice;  //판매하는 토큰(DOC)
    uint256 public payTokenPrice;   //받는 토큰(TON)

    uint256 public claimInterval; //클레임 간격 (epochtime)
    uint256 public claimPeriod;   //클레임 횟수
    uint256 public claimFirst;    //초기 클레임 percents

    uint256 public hardCap;       //hardcap 수량 (ton 기준)
    uint256 public changeTOS;     //ton -> tos로 변경하는 %
    uint256 public minPer;        //변경하는 % min
    uint256 public maxPer;        //변경하는 % max

    uint256 public stanTier1;     //최소 기준 Tier1
    uint256 public stanTier2;     //최소 기준 Tier2
    uint256 public stanTier3;     //최소 기준 Tier3
    uint256 public stanTier4;     //최소 기준 Tier4

    address public liquidityVaultAddress; //liquidityVault의 Address
    ISwapRouter public uniswapRouter;
    uint24 public constant poolFee = 3000;

    address public getTokenOwner;
    address public wton;
    address public getToken;

    IERC20 public saleToken;
    IERC20 public tos;
    ILockTOS public sTOS;

    address[] public depositors;
    address[] public whitelists;

    bool public adminWithdraw; //withdraw 실행여부

    uint256 public totalClaimCounts;
    uint256[] public claimTimes;
    uint256[] public claimPercents; 

    mapping (address => LibPublicSale.UserInfoEx) public usersEx;
    mapping (address => LibPublicSale.UserInfoOpen) public usersOpen;
    mapping (address => LibPublicSale.UserClaim) public usersClaim;

    mapping (uint => uint256) public tiers;         //티어별 가격 설정
    mapping (uint => uint256) public tiersAccount;  //티어별 화이트리스트 참여자 숫자 기록
    mapping (uint => uint256) public tiersExAccount;  //티어별 exclusiveSale 참여자 숫자 기록
    mapping (uint => uint256) public tiersPercents;  //티어별 퍼센트 기록
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import "./TickMath.sol";
import "./OracleLibrary.sol";

interface IIUniswapV3Factory {
    function getPool(address,address,uint24) external view returns (address);
}

interface IIUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

}

library LibPublicSale2 {
    function getQuoteAtTick(
        int24 tick,
        uint128 amountIn,
        address baseToken,
        address quoteToken
    ) public pure returns (uint256 amountOut) {
        return OracleLibrary.getQuoteAtTick(tick, amountIn, baseToken, quoteToken);
    }

    function getPoolAddress() public view returns(address) {
        address factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        address _wton = 0x709bef48982Bbfd6F2D4Be24660832665F53406C;
        address _tos = 0x73a54e5C054aA64C1AE7373C2B5474d8AFEa08bd;
        return IIUniswapV3Factory(factory).getPool(_wton, _tos, 3000);
    }

    function getMiniTick(int24 tickSpacings) public pure returns (int24){
        return (TickMath.MIN_TICK / tickSpacings) * tickSpacings ;
    }

    function getMaxTick(int24 tickSpacings) public pure  returns (int24){
        return (TickMath.MAX_TICK / tickSpacings) * tickSpacings ;
    }

    function acceptMinTick(int24 _tick, int24 _tickSpacings, int24 _acceptTickInterval) public pure returns (int24) {
        int24 _minTick = getMiniTick(_tickSpacings);
        int24 _acceptMinTick = _tick - (_tickSpacings * _acceptTickInterval);

        if(_minTick < _acceptMinTick) return _acceptMinTick;
        else return _minTick;
    }

    function acceptMaxTick(int24 _tick, int24 _tickSpacings, int24 _acceptTickInterval) public pure returns (int24) {
        int24 _maxTick = getMaxTick(_tickSpacings);
        int24 _acceptMinTick = _tick + (_tickSpacings * _acceptTickInterval);

        if(_maxTick < _acceptMinTick) return _maxTick;
        else return _acceptMinTick;
    }
    
    function limitPrameters(
        uint256 amountIn,
        address _pool,
        address token0,
        address token1,
        int24 acceptTickCounts
    ) public view returns  (uint256 amountOutMinimum, uint256 priceLimit, uint160 sqrtPriceX96Limit) {
        IIUniswapV3Pool pool = IIUniswapV3Pool(_pool);
        (, int24 tick,,,,,) =  pool.slot0();

        int24 _tick = tick;
        if(token0 < token1) {
            _tick = tick - acceptTickCounts * 60;
            if(_tick < TickMath.MIN_TICK ) _tick =  TickMath.MIN_TICK ;
        } else {
            _tick = tick + acceptTickCounts * 60;
            if(_tick > TickMath.MAX_TICK ) _tick =  TickMath.MAX_TICK ;
        }
        address token1_ = token1;
        address token0_ = token0;
        return (
              getQuoteAtTick(
                _tick,
                uint128(amountIn),
                token0_,
                token1_
                ),
             getQuoteAtTick(
                _tick,
                uint128(10**27),
                token0_,
                token1_
             ),
             TickMath.getSqrtRatioAtTick(_tick)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract AccessRoleCommon {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
    bytes32 public constant PROJECT_ADMIN_ROLE = keccak256("PROJECT_ADMIN_ROLE");
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../libraries/LibLockTOS.sol";


interface ILockTOS {
    
    /// @dev Returns addresses of all holders of LockTOS
    function allHolders() external returns (address[] memory);

    /// @dev Returns addresses of active holders of LockTOS
    function activeHolders() external returns (address[] memory);

    /// @dev Returns all withdrawable locks
    function withdrawableLocksOf(address user) external view returns (uint256[] memory);

    /// @dev Returns all locks of `_addr`
    function locksOf(address _addr) external view returns (uint256[] memory);

    /// @dev Returns all locks of `_addr`
    function activeLocksOf(address _addr) external view returns (uint256[] memory);

    /// @dev Total locked amount of `_addr`
    function totalLockedAmountOf(address _addr) external view returns (uint256);

    /// @dev     jhswuqhdiuwjhdoiehdoijijf   bhabcgfzvg tqafstqfzys amount of `_addr`
    function withdrawableAmountOf(address _addr) external view returns (uint256);

    /// @dev Returns all locks of `_addr`
    function locksInfo(uint256 _lockId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @dev Returns all history of `_addr`
    function pointHistoryOf(uint256 _lockId)
        external
        view
        returns (LibLockTOS.Point[] memory);

    /// @dev Total vote weight
    function totalSupply() external view returns (uint256);

    /// @dev Total vote weight at `_timestamp`
    function totalSupplyAt(uint256 _timestamp) external view returns (uint256);

    /// @dev Vote weight of lock at `_timestamp`
    function balanceOfLockAt(uint256 _lockId, uint256 _timestamp)
        external
        view
        returns (uint256);

    /// @dev Vote weight of lock
    function balanceOfLock(uint256 _lockId) external view returns (uint256);

    /// @dev Vote weight of a user at `_timestamp`
    function balanceOfAt(address _addr, uint256 _timestamp)
        external
        view
        returns (uint256 balance);

    /// @dev Vote weight of a iser
    function balanceOf(address _addr) external view returns (uint256 balance);

    /// @dev Increase amount
    function increaseAmount(uint256 _lockId, uint256 _value) external;

    /// @dev Deposits value for '_addr'
    function depositFor(
        address _addr,
        uint256 _lockId,
        uint256 _value
    ) external;

    /// @dev Create lock using permit
    function createLockWithPermit(
        uint256 _value,
        uint256 _unlockTime,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 lockId);

    /// @dev Create lock
    function createLock(uint256 _value, uint256 _unlockTime)
        external
        returns (uint256 lockId);

    /// @dev Increase
    function increaseUnlockTime(uint256 _lockId, uint256 unlockTime) external;

    /// @dev Withdraw all TOS
    function withdrawAll() external;

    /// @dev Withdraw TOS
    function withdraw(uint256 _lockId) external;
    
    /// @dev needCheckpoint
    function needCheckpoint() external view returns (bool need);

    /// @dev Global checkpoint
    function globalCheckpoint() external;

    /// @dev set MaxTime
    function setMaxTime(uint256 _maxTime) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

library LibPublicSale {
    struct UserInfoEx {
        bool join;
        uint tier;
        uint256 payAmount;
        uint256 saleAmount;
    }

    struct UserInfoOpen {
        bool join;
        uint256 depositAmount;
        uint256 payAmount;
    }

    struct UserClaim {
        bool exec;
        uint256 claimAmount;
        uint256 refundAmount;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

library LibLockTOS {
    struct Point {
        int256 bias;
        int256 slope;
        uint256 timestamp;
    }

    struct LockedBalance {
        uint256 start;
        uint256 end;
        uint256 amount;
        bool withdrawn;
    }

    struct SlopeChange {
        int256 bias;
        int256 slope;
        uint256 changeTime;
    }

    struct LockedBalanceInfo {
        uint256 id;
        uint256 start;
        uint256 end;
        uint256 amount;
        uint256 balance;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;

import '../libraries/FullMath.sol';
import '../libraries/TickMath.sol';


interface IIIUniswapV3Pool {

    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);


}

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {

    /// @notice Fetches time-weighted average tick using Uniswap V3 oracle
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @param period Number of seconds in the past to start calculating time-weighted average
    /// @return timeWeightedAverageTick The time-weighted average tick from (block.timestamp - period) to block.timestamp
    function consult(address pool, uint32 period) internal view returns (int24 timeWeightedAverageTick) {
        require(period != 0, 'BP');

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = period;
        secondAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IIIUniswapV3Pool(pool).observe(secondAgos);
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        timeWeightedAverageTick = int24(tickCumulativesDelta / int56( int32(period) ));

        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56( int32(period) ) != 0)) timeWeightedAverageTick--;
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // Handle division by zero
        require(denominator > 0);

        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            // require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }

        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        // 2022.0314.modified
        //uint256 twos = -denominator & denominator;
        //uint256 twos = denominator & (~denominator + 1);
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;

        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }

        //unchecked {
            prod0 |= prod1 * twos;
            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4

            uint256 inv = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        //}
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}