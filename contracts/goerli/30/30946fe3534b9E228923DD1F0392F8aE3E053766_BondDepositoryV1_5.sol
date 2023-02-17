// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./BondDepositoryStorage.sol";
import "./common/ProxyAccessCommon.sol";
import "./BondDepositoryStorageV1_5.sol";

import "./libraries/SafeERC20.sol";

import "./interfaces/IBondDepositoryV1_5.sol";
import "./interfaces/IBondDepositoryEventV1_5.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
// import "hardhat/console.sol";

interface IITreasury {
    function getMintRate() external view returns (uint256);
    function requestMint(uint256 _mintAmount, uint256 _payout, bool _distribute) external ;
    function addBondAsset(address _address) external;
}

interface IIOracleLibrary {
    function getOutAmountsCurTick(address factory, bytes memory _path, uint256 _amountIn)
        external view returns (uint256 amountOut);
}

interface IIBonusRateLockUpMap {
    function getRatesByWeeks(uint256 id, uint8 _weeks) external view returns (uint16 rates) ;
}

contract BondDepositoryV1_5 is
    BondDepositoryStorage,
    ProxyAccessCommon,
    BondDepositoryStorageV1_5,
    IBondDepositoryV1_5,
    IBondDepositoryEventV1_5
{
    using SafeERC20 for IERC20;

    modifier nonEndMarket(uint256 id_) {
        require(marketInfos[id_].startTime < block.timestamp, "no start time yet");
        require(!marketInfos[id_].closed, "closed market");
        require(markets[id_].endSaleTime > block.timestamp, "closed market");
        require(markets[id_].capacity > marketInfos[id_].totalSold, "zero capacity" );
        _;
    }

    modifier isEthMarket(uint256 id_) {
        require(markets[id_].quoteToken == address(0) && markets[id_].endSaleTime > 0,
            "not ETH market"
        );
        _;
    }

    modifier existedMarket(uint256 id_) {
        require(
            markets[id_].endSaleTime != 0,
            "non-exist market"
        );
        _;
    }

    modifier nonZeroUint32(uint32 value) {
        require(
            value != 0,
            "zero value"
        );
        _;
    }

    constructor() {
        remainingTosTolerance = 100 ether;
    }

    /// @inheritdoc IBondDepositoryV1_5
    function create(
        address _token,
        uint256[4] calldata _marketInfos,
        address _bonusRatesAddress,
        uint256 _bonusRatesId,
        uint32 _startTime,
        uint32 _endTime,
        bytes[] calldata _pathes
    )
        external override
        onlyPolicyOwner
        nonZero(_marketInfos[1])
        nonZero(_marketInfos[3])
        nonZeroUint32(_startTime)
        nonZeroUint32(_endTime)
        returns (uint256 id_)
    {
        //0. uint256 _capacity,
        //1. uint256 _lowerPriceLimit,
        //2. uint256 _initialMaxPayout,
        //3. uint256 _capacityUpdatePeriod,
        require(_marketInfos[0] > remainingTosTolerance, "totalSaleAmount is too small.");
        require(_endTime > _startTime && _endTime > uint16(block.timestamp), "invalid _startTime or endSaleTime");

        id_ = staking.generateMarketId();

        markets[id_] = LibBondDepository.Market({
                            quoteToken: _token,
                            capacity: _marketInfos[0],
                            endSaleTime: uint256(_endTime),
                            maxPayout: 0,
                            tosPrice: _marketInfos[1]
                        });

        marketList.push(id_);

        /// add v1.5
        // Market.capacity change the total capacity
        marketInfos[id_] = LibBondDepositoryV1_5.MarketInfo(
            {
                bondType: uint8(LibBondDepositoryV1_5.BOND_TYPE.MINTING_V1_5),
                startTime: _startTime,
                closed: false,
                initialMaxPayout: _marketInfos[2],
                capacityUpdatePeriod: _marketInfos[3],
                totalSold: 0
            }
        );

        if (_bonusRatesAddress != address(0) && _bonusRatesId != 0) {
            bonusRateInfos[id_] = LibBondDepositoryV1_5.BonusRateInfo(
                {
                    bonusRatesAddress: _bonusRatesAddress,
                    bonusRatesId: _bonusRatesId
                }
            );
        }

        if (_pathes.length != 0) {
            pricePathInfos[id_] = new bytes[](_pathes.length);
            for (uint256 i = 0; i < _pathes.length; i++){
                pricePathInfos[id_][i] = _pathes[i];
            }
        }

        if (_token != address(0)) IITreasury(treasury).addBondAsset(_token);

        emit CreatedMarket(
            id_,
            _token,
            _marketInfos,
            _bonusRatesAddress,
            _bonusRatesId,
            _startTime,
            _endTime,
            _pathes
            );
    }

    /// @inheritdoc IBondDepositoryV1_5
    function changeCapacity(
        uint256 _marketId,
        bool _increaseFlag,
        uint256 _increaseAmount
    )   external override onlyPolicyOwner
        nonZero(_increaseAmount)
        existedMarket(_marketId)
    {
        LibBondDepository.Market storage _info = markets[_marketId];
        LibBondDepositoryV1_5.MarketInfo storage _marketInfo = marketInfos[_marketId];

        if (_increaseFlag) _info.capacity += _increaseAmount;
        else {
            if (_increaseAmount <= (_info.capacity - _marketInfo.totalSold) ) _info.capacity -= _increaseAmount;
            else _info.capacity -= (_info.capacity - _marketInfo.totalSold);
        }

        if ( (_info.capacity - _marketInfo.totalSold) <= remainingTosTolerance ) {
            _marketInfo.closed = true;
            emit ClosedMarket(_marketId);
        }

        emit ChangedCapacity(_marketId, _increaseFlag, _increaseAmount);
    }

    /// @inheritdoc IBondDepositoryV1_5
    function changeCloseTime(
        uint256 _marketId,
        uint256 closeTime
    )   external override onlyPolicyOwner
        existedMarket(_marketId)
    {
        require(closeTime > block.timestamp, "past closeTime");

        LibBondDepository.Market storage _info = markets[_marketId];
        _info.endSaleTime = closeTime;

        emit ChangedCloseTime(_marketId, closeTime);
    }

    /// @inheritdoc IBondDepositoryV1_5
    function changeLowerPriceLimit(
        uint256 _marketId,
        uint256 _tosPrice
    )   external override onlyPolicyOwner
        nonEndMarket(_marketId)
        nonZero(_tosPrice)
    {
        LibBondDepository.Market storage _info = markets[_marketId];
        _info.tosPrice = _tosPrice;

        emit ChangedLowerPriceLimit(_marketId, _tosPrice);
    }

    /// @inheritdoc IBondDepositoryV1_5
    function changeOracleLibrary(
        address _oralceLibrary,
        address _uniswapFactory
    )   external override onlyPolicyOwner
        nonZeroAddress(_oralceLibrary)
    {
        require(oracleLibrary != _oralceLibrary || uniswapFactory != _uniswapFactory, "same address");
        oracleLibrary = _oralceLibrary;
        uniswapFactory = _uniswapFactory;

        emit ChangedOracleLibrary(_oralceLibrary, _uniswapFactory);
    }

    /// @inheritdoc IBondDepositoryV1_5
    function changeBonusRateInfo(
        uint256 _marketId,
        address _bonusRatesAddress,
        uint256 _bonusRatesId
    )   external override onlyPolicyOwner
        nonEndMarket(_marketId)
        nonZeroAddress(_bonusRatesAddress)
        nonZero(_bonusRatesId)
    {

        require(
            !(bonusRateInfos[_marketId].bonusRatesAddress == _bonusRatesAddress
            && bonusRateInfos[_marketId].bonusRatesId == _bonusRatesId),
            "same info");

        bonusRateInfos[_marketId] = LibBondDepositoryV1_5.BonusRateInfo(
            {
                bonusRatesAddress: _bonusRatesAddress,
                bonusRatesId: _bonusRatesId
            }
        );

        emit ChangedBonusRateInfo(_marketId, _bonusRatesAddress, _bonusRatesId);
    }


    /// @inheritdoc IBondDepositoryV1_5
    function changePricePathInfo(
        uint256 _marketId,
        bytes[] memory pathes
    )   external override onlyPolicyOwner
        nonEndMarket(_marketId)
    {
        if (pricePathInfos[_marketId].length != 0) {
            for (uint256 i = (pricePathInfos[_marketId].length-1); i > 0 ; i--){
                pricePathInfos[_marketId].pop();
            }
            pricePathInfos[_marketId].pop();
            delete pricePathInfos[_marketId];
        }

        if (pathes.length != 0) {
            pricePathInfos[_marketId] = new bytes[](pathes.length);
            for (uint256 i = 0; i < pathes.length; i++){
                pricePathInfos[_marketId][i] = pathes[i];
            }
        }

        emit ChangedPricePathInfo(_marketId, pathes);
    }

    /// @inheritdoc IBondDepositoryV1_5
    function close(uint256 _id) public override onlyPolicyOwner existedMarket(_id) {
        // require(markets[_id].endSaleTime > 0, "empty market");
        require(
            markets[_id].endSaleTime > block.timestamp
            || markets[_id].capacity <= remainingTosTolerance
            || marketInfos[_id].closed, "already closed");

        LibBondDepositoryV1_5.MarketInfo storage _marketInfo = marketInfos[_id];
        _marketInfo.closed = true;
        emit ClosedMarket(_id);
    }

    /// @inheritdoc IBondDepositoryV1_5
    function changeRemainingTosTolerance(uint256 _amount) external override onlyPolicyOwner {
        require(remainingTosTolerance != _amount, "same amount");
        remainingTosTolerance = _amount;
        emit ChangedRemainingTosTolerance(_amount);
    }

    ///////////////////////////////////////
    /// Anyone can use.
    //////////////////////////////////////

    /// @inheritdoc IBondDepositoryV1_5
    function ETHDeposit(
        uint256 _id,
        uint256 _amount,
        uint256 _minimumTosPrice
    )
        external payable override
        nonEndMarket(_id)
        isEthMarket(_id)
        nonZero(_amount)
        returns (uint256 payout_)
    {
        require(msg.value == _amount, "Depository: ETH amounts do not match");

        uint256 _tosPrice = 0;

        (payout_, _tosPrice) = _deposit(msg.sender, _amount, _minimumTosPrice, _id, 0);

        uint256 stakeId = staking.stakeByBond(
            msg.sender,
            payout_,
            _id,
            _tosPrice
        );

        payable(treasury).transfer(msg.value);

        emit ETHDeposited(msg.sender, _id, stakeId, _amount, _minimumTosPrice, payout_);
    }


    /// @inheritdoc IBondDepositoryV1_5
    function ETHDepositWithSTOS(
        uint256 _id,
        uint256 _amount,
        uint256 _minimumTosPrice,
        uint8 _lockWeeks
    )
        external payable override
        nonEndMarket(_id)
        isEthMarket(_id)
        nonZero(_amount)
        returns (uint256 payout_)
    {
        require(msg.value == _amount, "Depository: ETH amounts do not match");

        require(_lockWeeks > 1, "_lockWeeks must be greater than 1 week.");
        uint256 _tosPrice = 0;
        (payout_, _tosPrice) = _deposit(msg.sender, _amount, _minimumTosPrice, _id, _lockWeeks);

        uint256 stakeId = staking.stakeGetStosByBond(msg.sender, payout_, _id, uint256(_lockWeeks), _tosPrice);

        payable(treasury).transfer(msg.value);

        emit ETHDepositedWithSTOS(msg.sender, _id, stakeId, _amount, _minimumTosPrice, _lockWeeks, payout_);
    }


    function _deposit(
        address user,
        uint256 _amount,
        uint256 _minimumTosPrice,
        uint256 _marketId,
        uint8 _lockWeeks
    ) internal nonReentrant returns (uint256 _payout, uint256 bondingPrice) {

        LibBondDepository.Market memory market = markets[_marketId];

        // 이더당 tos 양
        (uint256 basePrice, , ) = getBasePrice(_marketId);

        // 이더당 토스양 , 락업을 많이 할 수록 토스를 더 많이 받을 수 있다.
        bondingPrice = getBondingPrice(_marketId, _lockWeeks, basePrice);

        require(bondingPrice >= _minimumTosPrice, "The bonding amount is less than the minimum amount.");

        _payout = (_amount * bondingPrice / 1e18);
        require(_payout + marketInfos[_marketId].totalSold <= market.capacity, "sales volume is lacking");

        (, uint256 currentCapacity) = possibleMaxCapacity(_marketId);

        require(_payout <= currentCapacity, "exceed currentCapacityLimit");

        uint256 mrAmount = _amount * IITreasury(treasury).getMintRate() / 1e18;
        require(mrAmount >= _payout, "mintableAmount is less than staking amount.");

        LibBondDepositoryV1_5.MarketInfo storage _marketInfo = marketInfos[_marketId];
        _marketInfo.totalSold += _payout;

        //check closing
        if (market.capacity - _marketInfo.totalSold <= remainingTosTolerance) {
           _marketInfo.closed = true;
           emit ClosedMarket(_marketId);
        }

        IITreasury(treasury).requestMint(mrAmount, _payout, true);

        emit Deposited(user, _marketId, _amount, _payout, true, mrAmount);
    }

    ///////////////////////////////////////
    /// VIEW
    //////////////////////////////////////

    /// @inheritdoc IBondDepositoryV1_5
    function getBonds() external override view
        returns (
            uint256[] memory,
            LibBondDepositoryV1_5.MarketInfo[] memory,
            LibBondDepositoryV1_5.BonusRateInfo[] memory
        )
    {
        uint256 len = marketList.length;
        uint256[] memory _marketIds = new uint256[](len);
        LibBondDepositoryV1_5.BonusRateInfo[] memory _bonusInfo = new LibBondDepositoryV1_5.BonusRateInfo[](len);
        LibBondDepositoryV1_5.MarketInfo[] memory _marketInfo = new LibBondDepositoryV1_5.MarketInfo[](len);

        for (uint256 i = 0; i < len; i++){
            uint256 id = _marketIds[i];
            _bonusInfo[i] = bonusRateInfos[id];
            _marketInfo[i] = marketInfos[id];
        }
        return (_marketIds, _marketInfo, _bonusInfo);
    }

    /// @inheritdoc IBondDepositoryV1_5
    function getMarketList() external override view returns (uint256[] memory) {
        return marketList;
    }

    /// @inheritdoc IBondDepositoryV1_5
    function totalMarketCount() external override view returns (uint256) {
        return marketList.length;
    }

    /// @inheritdoc IBondDepositoryV1_5
    function viewMarket(uint256 _marketId) external override view
        returns (
            LibBondDepository.Market memory market,
            LibBondDepositoryV1_5.MarketInfo memory marketInfo,
            LibBondDepositoryV1_5.BonusRateInfo memory bonusInfo,
            bytes[] memory pricePathes
            )
    {
        return (
            markets[_marketId],
            marketInfos[_marketId],
            bonusRateInfos[_marketId],
            pricePathInfos[_marketId]
        );
    }

    /// @inheritdoc IBondDepositoryV1_5
    function isOpened(uint256 _marketId) external override view returns (bool closedBool)
    {
        return
            (block.timestamp < markets[_marketId].endSaleTime
            && markets[_marketId].capacity > (marketInfos[_marketId].totalSold + remainingTosTolerance));
    }


    function getBondingPrice(uint256 _marketId, uint8 _lockWeeks, uint256 basePrice)
        public override view
        returns (uint256 bondingPrice)
    {
        (basePrice,,) = getBasePrice(_marketId);

        if (basePrice > 0 && _lockWeeks > 0) {
            LibBondDepositoryV1_5.BonusRateInfo memory bonusInfo = bonusRateInfos[_marketId];
            if (bonusInfo.bonusRatesAddress != address(0) && bonusInfo.bonusRatesId != 0) {
                uint16 rates = IIBonusRateLockUpMap(bonusInfo.bonusRatesAddress).getRatesByWeeks(bonusInfo.bonusRatesId, _lockWeeks);
                if (rates > 0) {
                    bondingPrice = basePrice + (basePrice * uint256(rates) / 10000) ;
                }
            }
        }

        if (bondingPrice == 0) bondingPrice = basePrice;
    }

    function getBasePrice(uint256 _marketId)
        public override view
        returns (uint256 basePrice, uint256 lowerPriceLimit, uint256 uniswapPrice)
    {
        lowerPriceLimit = markets[_marketId].tosPrice;
        uniswapPrice = getUniswapPrice(_marketId);
        basePrice = Math.max(lowerPriceLimit, uniswapPrice);
    }

    function getUniswapPrice(uint256 _marketId)
        public override view
        returns (uint256 uniswapPrice)
    {
        bytes[] memory pathes = pricePathInfos[_marketId];
        if (pathes.length > 0){
            uint256 prices = 0;
            for (uint256 i = 0; i < pathes.length; i++){

                prices = IIOracleLibrary(oracleLibrary).getOutAmountsCurTick(uniswapFactory, pathes[i], 1 ether);

                if (i == 0) uniswapPrice = prices;
                else uniswapPrice = Math.max(uniswapPrice, prices);
            }
        }
    }

    /// @inheritdoc IBondDepositoryV1_5
    function possibleMaxCapacity (
        uint256 _marketId
    )
        public override view returns (uint256 periodicCapacity, uint256 currentCapacity)
    {
        (uint256 _numberOfPeriods, uint256 _numberOfPeriodsPassed) = salePeriod(_marketId);

        LibBondDepository.Market memory market = markets[_marketId];
        LibBondDepositoryV1_5.MarketInfo memory capacityInfo = marketInfos[_marketId];

        if (_numberOfPeriods > 0)
            periodicCapacity = market.capacity / _numberOfPeriods;

        if (_numberOfPeriodsPassed > 0 && periodicCapacity * _numberOfPeriodsPassed > capacityInfo.totalSold)
                currentCapacity = periodicCapacity * _numberOfPeriodsPassed - capacityInfo.totalSold;
    }

    /// @inheritdoc IBondDepositoryV1_5
    function salePeriod(uint256 _marketId) public override view returns (uint256 numberOfPeriods, uint256 numberOfPeriodsPassed) {

        LibBondDepositoryV1_5.MarketInfo memory capacityInfo = marketInfos[_marketId];

        if (capacityInfo.startTime > 0){
            LibBondDepository.Market memory market = markets[_marketId];

            if (market.endSaleTime > capacityInfo.startTime){
                uint256 periodSeconds = market.endSaleTime - capacityInfo.startTime;
                numberOfPeriods = periodSeconds /  capacityInfo.capacityUpdatePeriod;
                if (capacityInfo.capacityUpdatePeriod > 1 && periodSeconds % capacityInfo.capacityUpdatePeriod > 0)
                    numberOfPeriods++;

                if (block.timestamp > capacityInfo.startTime && block.timestamp < market.endSaleTime ) {
                    numberOfPeriodsPassed = (block.timestamp - capacityInfo.startTime) / capacityInfo.capacityUpdatePeriod;

                    uint256 passedTime = (block.timestamp - capacityInfo.startTime) % capacityInfo.capacityUpdatePeriod ;
                    if (capacityInfo.capacityUpdatePeriod > 1 && passedTime > 0) numberOfPeriodsPassed++;
                }
            }
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./libraries/LibBondDepository.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IStaking.sol";

contract BondDepositoryStorage {

    IERC20 public tos;
    IStaking public staking;
    address public treasury;
    address public calculator;
    address public uniswapV3Factory;
    address public dtos;

    bool private _entered;

    uint256[] public marketList;
    mapping(uint256 => LibBondDepository.Market) public markets;


    modifier nonZero(uint256 tokenId) {
        require(tokenId != 0, "BondDepository: zero uint");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(
            account != address(0),
            "BondDepository:zero address"
        );
        _;
    }

    modifier nonReentrant() {
        require(_entered != true, "ReentrancyGuard: reentrant call");

        _entered = true;

        _;

        _entered = false;
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./libraries/LibBondDepositoryV1_5.sol";

contract BondDepositoryStorageV1_5 {
    uint256 public remainingTosTolerance;
    address public oracleLibrary;
    address public uniswapFactory;
    uint32 public oracleConsultPeriod;
    uint8 public maxLockupWeeks;

    /// marketId - MarketInfo
    mapping(uint256 => LibBondDepositoryV1_5.MarketInfo) marketInfos;

    /// marketId - BonusRateInfo
    mapping(uint256 => LibBondDepositoryV1_5.BonusRateInfo) bonusRateInfos;

    /// marketId - PricePathInfo
    mapping(uint256 => bytes[]) pricePathInfos;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "../libraries/LibBondDepositoryV1_5.sol";
import "../libraries/LibBondDepository.sol";

interface IBondDepositoryV1_5 {

    ///////////////////////////////////////
    /// onlyPolicyOwner
    //////////////////////////////////////

    /// @dev                        creates a new market type
    /// @param token                token address of deposit asset. For ETH, the address is address(0). Will be used in Phase 2 and 3
    /// @param marketInfos          [capacity, maxPayout, lowerPriceLimit, initialMaxPayout, capacityUpdatePeriod]
    ///                             capacity             maximum purchasable bond in TOS
    ///                             lowerPriceLimit     lowerPriceLimit
    ///                             initialMaxPayout    initial max payout
    ///                             capacityUpdatePeriod capacity update period(seconds)
    /// @param bonusRatesAddress    bonusRates logic address
    /// @param bonusRatesId         bonusRates id
    /// @param startTime            start time
    /// @param endTime              market closing time
    /// @param pathes               pathes for find out the price
    /// @return id_                 returns ID of new bond market
    function create(
        address token,
        uint256[4] calldata marketInfos,
        address bonusRatesAddress,
        uint256 bonusRatesId,
        uint32 startTime,
        uint32 endTime,
        bytes[] calldata pathes
    ) external returns (uint256 id_);


    /**
     * @dev                   change the market capacity
     * @param _marketId       marketId
     * @param _increaseFlag   if true, increase capacity, otherwise decrease capacity
     * @param _increaseAmount the capacity amount
     */
    function changeCapacity(
        uint256 _marketId,
        bool _increaseFlag,
        uint256 _increaseAmount
    )   external;


    /**
     * @dev                changes the market closeTime
     * @param _marketId    marketId
     * @param closeTime    closeTime
     */
    function changeCloseTime(
        uint256 _marketId,
        uint256 closeTime
    )   external ;

    /**
     * @dev                changes the market price
     * @param _marketId    marketId
     * @param _tosPrice    tosPrice
     */
    function changeLowerPriceLimit(
        uint256 _marketId,
        uint256 _tosPrice
    )   external ;

    /**
     * @dev                     changes the oralce library address
     * @param _oralceLibrary    oralce library address
     * @param _uniswapFactory   uniswapFactory address
     */
    function changeOracleLibrary(
        address _oralceLibrary,
        address _uniswapFactory
    )   external ;

    /**
     * @dev                             changes bonus rate info
     * @param _marketId                 market id
     * @param _bonusRatesAddress     bonus rates address
     * @param _bonusRatesId          bonus rates id
     */
    function changeBonusRateInfo(
        uint256 _marketId,
        address _bonusRatesAddress,
        uint256 _bonusRatesId
    )   external ;

    /**
     * @dev                             this event occurs when the price path info is updated
     * @param _marketId                 market id
     * @param pathes                    path for pricing
     */
    function changePricePathInfo(
        uint256 _marketId,
        bytes[] calldata pathes
    )   external ;

    /**
     * @dev        closes the market
     * @param _id  market id
     */
    function close(uint256 _id) external;

     /**
     * @dev             change remaining TOS tolerance
     * @param _amount   tolerance
     */
    function changeRemainingTosTolerance(uint256 _amount) external;

    ///////////////////////////////////////
    /// Anyone can use.
    //////////////////////////////////////

    /// @dev                        deposit with ether that does not earn sTOS
    /// @param _id                  market id
    /// @param _amount              amount of deposit in ETH
    /// @param _minimumTosPrice     the minimum tos price
    /// @return payout_             returns amount of TOS earned by the user
    function ETHDeposit(
        uint256 _id,
        uint256 _amount,
        uint256 _minimumTosPrice
    ) external payable returns (uint256 payout_ );


    /// @dev                        deposit with ether that earns sTOS
    /// @param _id                  market id
    /// @param _amount              amount of deposit in ETH
    /// @param _minimumTosPrice     the maximum tos price
    /// @param _lockWeeks           number of weeks for lock
    /// @return payout_             returns amount of TOS earned by the user
    function ETHDepositWithSTOS(
        uint256 _id,
        uint256 _amount,
        uint256 _minimumTosPrice,
        uint8 _lockWeeks
    ) external payable returns (uint256 payout_);


    ///////////////////////////////////////
    /// VIEW
    //////////////////////////////////////

    /// @dev                        returns information from active markets
    /// @return marketIds           array of total marketIds
    /// @return marketInfo          array of total market's information
    /// @return bonusRateInfo       array of total market's bonusRateInfos
    function getBonds() external view
        returns (
            uint256[] memory marketIds,
            LibBondDepositoryV1_5.MarketInfo[] memory marketInfo,
            LibBondDepositoryV1_5.BonusRateInfo[] memory bonusRateInfo
        );

    /// @dev                returns all generated marketIDs
    /// @return memory[]    returns marketList
    function getMarketList() external view returns (uint256[] memory) ;

    /// @dev                    returns the number of created markets
    /// @return                 Total number of markets
    function totalMarketCount() external view returns (uint256) ;

    /// @dev                    turns information about the market
    /// @param _marketId        market id
    /// @return market          market base information
    /// @return marketInfo      market information
    /// @return bonusInfo       bonus information
    /// @return pricePathes     pathes for price
    function viewMarket(uint256 _marketId) external view
        returns (
            LibBondDepository.Market memory market,
            LibBondDepositoryV1_5.MarketInfo memory marketInfo,
            LibBondDepositoryV1_5.BonusRateInfo memory bonusInfo,
            bytes[] memory pricePathes
            );

    /// @dev               checks whether a market is opened or not
    /// @param _marketId   market id
    /// @return closedBool true if market is open, false if market is closed
    function isOpened(uint256 _marketId) external view returns (bool closedBool);

    /// @dev                    get bonding price
    /// @param _marketId        market id
    /// @param _lockWeeks       lock weeks
    /// @param basePrice       base price
    /// @return bondingPrice    bonding price
    function getBondingPrice(uint256 _marketId, uint8 _lockWeeks, uint256 basePrice)
        external view
        returns (uint256 bondingPrice);


    /// @dev                    get base price
    /// @param _marketId        market id
    /// @return basePrice       base price
    /// @return lowerPriceLimit lower price limit
    /// @return uniswapPrice    uniswap price
    function getBasePrice(uint256 _marketId)
        external view
        returns (uint256 basePrice, uint256 lowerPriceLimit, uint256 uniswapPrice);

    function getUniswapPrice(uint256 _marketId)
        external view
        returns (uint256 uniswapPrice);

    /// @dev                        calculate the possible max capacity
    /// @param _marketId            market id
    /// @return periodicCapacity    the periodic capacity
    /// @return currentCapacity     the current capacity
    function possibleMaxCapacity(
        uint256 _marketId
    ) external view returns (uint256 periodicCapacity, uint256 currentCapacity);


    /// @dev                            calculate the sale periods
    /// @param _marketId                market id
    /// @return numberOfPeriods         number of periods
    /// @return numberOfPeriodsPassed   number of periods passed
    function salePeriod(
        uint256 _marketId
    ) external view returns (uint256 numberOfPeriods, uint256 numberOfPeriodsPassed);


}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;
import "../libraries/LibBondDepositoryV1_5.sol";

interface IBondDepositoryEventV1_5 {


    /// @dev                        this event occurs when set the calculator address
    /// @param calculatorAddress    calculator address
    event SetCalculator(address calculatorAddress);

    /// @dev               this event occurs when a specific market product is purchased
    /// @param user        user address
    /// @param marketId    market id
    /// @param amount      bond amount in ETH
    /// @param payout      amount of TOS earned by the user from bonding
    /// @param isEth       whether ether was used for bonding
    /// @param mintAmount  number of minted TOS from this deposit
    event Deposited(address user, uint256 marketId, uint256 amount, uint256 payout, bool isEth, uint256 mintAmount);


    /// @dev                        this event occurs when a specific market product is created
    /// @param marketId             market id
    /// @param token                token address of deposit asset. For ETH, the address is address(0). Will be used in Phase 2 and 3
    /// @param marketInfos          [capacity, lowerPriceLimit, initialMaxPayout, capacityUpdatePeriod]
    ///                             capacity            capacity of the market
    ///                             lowerPriceLimit     lowerPriceLimit
    ///                             initialMaxPayout    initial max payout
    ///                             capacityUpdatePeriod capacity update period(seconds)
    /// @param bonusRatesAddress    bonusRates logic address
    /// @param bonusRatesId         bonusRates id
    /// @param startTime            start time
    /// @param endTime              market closing time
    /// @param pathes               pathes
    event CreatedMarket(
        uint256 marketId,
        address token,
        uint256[4] marketInfos,
        address bonusRatesAddress,
        uint256 bonusRatesId,
        uint32 startTime,
        uint32 endTime,
        bytes[] pathes
        );


    /// @dev            this event occurs when a specific market product is closed
    /// @param marketId market id
    event ClosedMarket(uint256 marketId);

    /// @dev            this event occurs when change remaining TOS tolerance
    /// @param amount   amount
    event ChangedRemainingTosTolerance(uint256 amount);

    /// @dev                        this event occurs when a user bonds with ETH
    /// @param user                 user account
    /// @param marketId             market id
    /// @param stakeId              stake id
    /// @param amount               amount of deposit in ETH
    /// @param minimumTosPrice      the minimum tos price
    /// @param tosValuation         amount of TOS earned by the user
    event ETHDeposited(address user, uint256 marketId, uint256 stakeId, uint256 amount, uint256 minimumTosPrice, uint256 tosValuation);

    /// @dev                        this event occurs when a user bonds with ETH and earns sTOS
    /// @param user                 user account
    /// @param marketId             market id
    /// @param stakeId              stake id
    /// @param amount               amount of deposit in ETH
    /// @param minimumTosPrice      the minimum tos price
    /// @param lockWeeks            number of weeks to locking
    /// @param tosValuation         amount of TOS earned by the user
    event ETHDepositedWithSTOS(address user, uint256 marketId, uint256 stakeId, uint256 amount, uint256 minimumTosPrice, uint8 lockWeeks, uint256 tosValuation);

    /// @dev                   this event occurs when the market capacity is changed
    /// @param _marketId       market id
    /// @param _increaseFlag   if true, increase capacity, otherwise decrease capacity
    /// @param _increaseAmount the capacity amount
    event ChangedCapacity(uint256 _marketId, bool _increaseFlag, uint256  _increaseAmount);

    /// @dev             this event occurs when the closeTime is updated
    /// @param _marketId market id
    /// @param closeTime new close time
    event ChangedCloseTime(uint256 _marketId, uint256 closeTime);

    /// @dev                            this event occurs when the bonus rate info is updated
    /// @param _marketId                market id
    /// @param bonusRatesAddress     bonus rates address
    /// @param bonusRatesId          bonus rates id
    event ChangedBonusRateInfo(uint256 _marketId, address bonusRatesAddress, uint256 bonusRatesId);

    /// @dev                            this event occurs when the price path info is updated
    /// @param _marketId                market id
    /// @param pathes                   price path
    event ChangedPricePathInfo(uint256 _marketId, bytes[] pathes);

    /// @dev             this event occurs when the maxPayout is updated
    /// @param _marketId market id
    /// @param _tosPrice amount of TOS per 1 ETH
    event ChangedLowerPriceLimit(uint256 _marketId, uint256 _tosPrice);

    /// @dev            this event occurs when oracle library is changed
    /// @param oralceLibrary oralceLibrary address
    /// @param uniswapFactory uniswapFactory address
    event ChangedOracleLibrary(address oralceLibrary, address uniswapFactory);

    /// @dev             this event occurs when the maxPayout is updated
    /// @param _marketId market id
    /// @param _pools    pool addresses of uniswap for determaining a price
    event ChangedPools(uint256 _marketId, address[] _pools);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title LibBondDepository
library LibBondDepository
{
     // Info about each type of market
    struct Market {
        address quoteToken;  //token to accept as payment
        uint256 capacity;   //remain sale volume
        uint256 endSaleTime;    //saleEndTime
        uint256 maxPayout;  // 한 tx에 살수 있는 물량
        uint256 tosPrice;
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title LibBondDepositoryV1_5
library LibBondDepositoryV1_5
{
    enum BOND_TYPE {
        MINTING_V1,
        MINTING_V1_5,
        LIQUIDITY_V1_5
    }

    // market market info
    struct MarketInfo {
        uint8 bondType;
        uint32 startTime;
        bool closed;
        uint256 initialMaxPayout;
        uint256 capacityUpdatePeriod;
        uint256 totalSold;
    }

    struct BonusRateInfo {
        address bonusRatesAddress;
        uint256 bonusRatesId;
    }
}