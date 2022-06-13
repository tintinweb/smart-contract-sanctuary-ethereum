//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "./interfaces/IOddzConfig.sol";
import "./interfaces/IOrderManager.sol";
import "./interfaces/IOddzMarket.sol";
import "./interfaces/IIndexPrice.sol";
import "./interfaces/IBalanceManager.sol";
import "./interfaces/ISwapManager.sol";
import "./utils/oddzOwnable.sol";
import "./maths/OddzMath.sol";
import "./interfaces/IOddzVault.sol";
import "./maths/OddzSafeCast.sol";

contract BalanceManager is OddzOwnable, IBalanceManager {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using OddzSafeCast for uint256;
    using OddzSafeCast for uint128;
    using OddzSafeCast for int256;
    using OddzMath for uint256;
    using OddzMath for uint128;
    using OddzMath for int256;

    // VARIALBLES
    //

    address public oddzConfig;
    address public oddzVault;
    address public oddzClearingHouse;
    address public orderManager;
    address public oddzMarket;
    address public insuranceManager;
    address public swapManager;
    address public oddzClearingHouseExtended;
    
    //event 
    event updatedInsuranceFee(int256 _amount);
   


    // trader => baseTokens
    // base tokens of each trader
    // mapping(address => address[]) internal traderBaseTokens;

    // trader => total collateral used by the trader for positions
    mapping(address => uint256) internal totalUsedCollateralInPositions;

    //trader =>  positionIDs
    mapping(address => uint256[]) internal traderPositions;

    //positionId =>  index of position id in traderPositions array
    mapping(uint256 => uint256) internal positionIndex;

    // first key: id , second key : position info
    mapping(uint256 => PositionInfo) internal traderPositionInfo;

    //trader=> groupIDs
    mapping(address => uint256[]) internal traderGroups;

    // first key is the address of the trader , second key is the default group id
    mapping(address => uint256) internal traderDefaultGroup;

    // group id => group info
    mapping(uint256 => GroupInfo) public groupInfo;
    
    // trader => ownedFees
    mapping(address => int256) public ownedFees;

    // trader => groupId : owedRealizedPnl
    mapping(address => mapping(uint => int256 )) public groupedOwedRealizedPnl;

    uint256 internal constant _DUST = 10 wei;

    //EVENTS

    /// @dev Emit whenever a position's `owedRealizedPnl` is updated	
    /// @param positionId The position id of the trader	
    /// @param amount The amount changed	
    event PnlRealized(uint256 indexed positionId, int256 amount);

    modifier onlyClearingHouse() {
        require(
            _msgSender() == oddzClearingHouse ||_msgSender() == oddzClearingHouseExtended,
            "BalanceManager: Only clearhouse and clearhouse extended allowed"
        );
        _;
    }

    modifier onlyOddzVault() {
        require(
            _msgSender() == oddzVault,
            "BalanceManager: Only vault allowed"
        );
        _;
    }

    function initialize(address _oddzConfig, address _oddzVault, address _insuranceManager)
        external
        initializer
    {
        require(
            _oddzConfig.isContract(),
            "BalanceManager : config address is not a contract"
        );
        require(
            _oddzVault.isContract(),
            "BalanceManager : oddz vault address is not a contract"
        );
        require(
            _insuranceManager.isContract(),
            "BalanceManager : isurance manager address is not a contract"
        );
        __OddzOwnable_init();
        oddzConfig = _oddzConfig;
        oddzVault = _oddzVault;
        insuranceManager=_insuranceManager;
    }

    /**
     * @notice Used to update clearing house contract address
     * @param _clearingHouse Address of the clearing house contract
     */

    function updateClearingHouse(address _clearingHouse) external onlyOwner {
        require(
            _clearingHouse.isContract(),
            "BalanceManager : clearing house address is not a contract"
        );
        oddzClearingHouse = _clearingHouse;
    }

    /**
     * @notice Used to update Order Manager contract address
     * @param _orderManager Address of the clearing house contract
     */

    function updateOrderManager(address _orderManager) external onlyOwner {
        require(
            _orderManager.isContract(),
            "BalanceManager : order Manager address is not a contract"
        );
        orderManager = _orderManager;
    }

    /**
     * @notice Used to update Oddz Market contract address
     * @param _oddzMarket Address of the oddz market contract
     */

    function updateOddzMarket(address _oddzMarket) external onlyOwner {
        require(
            _oddzMarket.isContract(),
            "BalanceManager : Oddz market address is not a contract"
        );
        oddzMarket = _oddzMarket;
    }

     /**
     * @notice Used to update swap manager contract address
     * @param _swapManager Address of the swap manager contract
     */

    function updateSwapManager(address _swapManager) external onlyOwner {
        require(
            _swapManager.isContract(),
            "BalanceManager : Swap Manager address is not a contract"
        );
        swapManager = _swapManager;
    }

    /**
     * @notice Used to update clearing house contract address
     * @param _clearingHouseExtended Address of the clearing house contract
     */

    function updateClearingHouseExtended(address _clearingHouseExtended) external onlyOwner {
        require(
            _clearingHouseExtended.isContract(),
            "BalanceManager : clearing house extended address is not a contract"
        );
        oddzClearingHouseExtended = _clearingHouseExtended;
    }

    /**
     * @notice Used to update positions id and collateral of a trader
     * @param _trader Address of the trader
     * @param _positionID position id
     * @param _collateralForPosition collateral used in position
     * @param _existing   if the position id already exist or not
     * @param _group     if position is in any group or not
     * @param _push       true if we want to add the position and false if we want to remove position
     */
    function updateTraderPositions(
        address _trader,
        uint256 _positionID,
        uint256 _collateralForPosition,
        bool _existing,
        bool _group,
        bool _push
    ) external override onlyClearingHouse {
        _updateTraderPositions(
            _trader,
            _positionID,
            _collateralForPosition,
            _existing,
            _group,
            _push
        );
    }

    /**
     * @notice Used to set the default group for the trader
     * @param _trader Address of the trader
     * @param _id default group id
     */
    function updateTraderDefaultGroupID(address _trader, uint256 _id)
        external
        override
        onlyClearingHouse
    {
        require(
            traderDefaultGroup[_trader] == 0,
            "BalanceManager:Default group already created"
        );
        traderDefaultGroup[_trader] = _id;
        traderGroups[_trader].push(_id);
        groupInfo[_id].trader = _trader;
    }

    /**
     * @notice Used to update groups ,positions in groups and collateral of a trader
     * @param _trader Address of the trader
     * @param _baseToken base token address
     * @param _positionID position id
     * @param _groupID  group id
     * @param _collateralForPosition collateral used in position
     * @param _isNewGroup  is this a new group or existing
     * @param _existing   if the position id already exist or not
     * @param _push       true if we want to add the position and false if we want to remove position
     */
    function updateTraderGroups(
        address _trader,
        address _baseToken,
        uint256 _positionID,
        uint256 _groupID,
        uint256 _collateralForPosition,
        bool _isNewGroup,
        bool _existing,
        bool _push
    ) external override onlyClearingHouse {
        _updateTraderGroups(
            _trader,
            _baseToken,
            _positionID,
            _groupID,
            _collateralForPosition,
            _isNewGroup,
            _existing,
            _push
        );
    }

    /**
     *@notice This function updates the group and position info for the trader.
     *@dev Is called by oddz Clearing house when moving positions
     *@param _positionID position id
     *@param _groupPositionID position id of the group to which position is going to merge
     *@param _groupID  group id of the destination position
     *@param _sourceRealizedPnL realized PnL of the source position
     *@param _sourceGroupID group id of the source position
     *@param _collateral  collateral allocated
     *@param _merge if two positions are merged or not
     */
    function updateTraderGroupAndPosition(
        uint256 _positionID,
        uint256 _groupPositionID,
        uint256 _groupID,
        int256 _sourceRealizedPnL,
        uint256 _sourceGroupID,
        uint256 _collateral,
        bool _merge
    ) external override onlyClearingHouse {
        PositionInfo memory positionInfo = traderPositionInfo[_positionID];
        uint256 positionCollateral = traderPositionInfo[_positionID]
            .collateralForPosition;
        traderPositionInfo[_positionID].collateralForPosition = 0;
        groupInfo[_groupID].collateralAllocated = groupInfo[_groupID]
            .collateralAllocated
            .add(positionCollateral)
            .add(_collateral);
        totalUsedCollateralInPositions[
            positionInfo.trader
        ] = totalUsedCollateralInPositions[positionInfo.trader].add(
            _collateral
        );
        if (_sourceGroupID > 0) {
            _updatePositionsInGroup(_positionID, _sourceGroupID);
        }
        if (!_merge) {
            GroupPositionsInfo[] storage groupPositions = groupInfo[_groupID]
                .groupPositions;
            GroupPositionsInfo memory gpInfo = GroupPositionsInfo({
                positionID: _positionID,
                baseToken: positionInfo.baseToken
            });
            groupPositions.push(gpInfo);

            // if default group then no limit on positions
            if (traderDefaultGroup[positionInfo.trader] != _groupID) {
                require(
                    groupPositions.length <=
                        IOddzConfig(oddzConfig).maxPositionsPerGroup(),
                    "BalanceManager:Max positions per group exceeded"
                );
            }
        } else {
            traderPositionInfo[_groupPositionID]
                .owedRealizedPnl = traderPositionInfo[_groupPositionID]
                .owedRealizedPnl
                .add(_sourceRealizedPnL);
            delete traderPositionInfo[_positionID];
            uint256[] storage allPositions = traderPositions[
                positionInfo.trader
            ];

            uint256 positionsLength = allPositions.length;
            uint256 index = positionIndex[_positionID];
            if (index != positionsLength - 1) {
                allPositions[index] = allPositions[positionsLength - 1];
                positionIndex[allPositions[index]] = index;
            }
            allPositions.pop();
            delete positionIndex[_positionID];
            _updateTraderGroups(
                positionInfo.trader,
                positionInfo.baseToken,
                _groupPositionID,
                _groupID,
                0,
                false,
                true,
                false
            );
        }
    }

    /**
    *@notice updates the position in the particular group
    *@param _positionID position id in the group 
    *@param _groupID group to be updated
     */
    function updatePositionsInGroup(uint256 _positionID, uint256 _groupID)
        external
        override
        onlyClearingHouse
    {
        _updatePositionsInGroup(_positionID, _groupID);
    }

    /**
    *@notice updates the collateral amount of the position
    *@param _positionID position id in the group 
    *@param _collateral collateral amount
     */
    function updateCollateral(uint256 _positionID, uint256 _collateral)
        external
        override
        onlyClearingHouse
    {
        traderPositionInfo[_positionID]
            .collateralForPosition = traderPositionInfo[_positionID]
            .collateralForPosition
            .add(_collateral);
        totalUsedCollateralInPositions[
            traderPositionInfo[_positionID].trader
        ] = totalUsedCollateralInPositions[
            traderPositionInfo[_positionID].trader
        ].add(_collateral);
    }

    /**
     * @notice updates postionSize and quoteSize of the trader.Can only be called by oddz clearing house
     * @param _baseToken  base token address
     * @param _positionId  position id
     * @param _baseAmount the base token amount
     * @param _quoteAmount the quote token amount
     * @param _groupId     group id if position is in any group otherwise 0
     * returns updated values
     */
    function updateTraderPositionInfo(
        address _trader,
        address _baseToken,
        uint256 _positionId,
        int256 _baseAmount,
        int256 _quoteAmount,
        uint256 _groupId
    ) external override onlyClearingHouse returns (int256, int256) {
        return
            _updateTraderPositionInfo(
                _trader,
                _baseToken,
                _positionId,
                _baseAmount,
                _quoteAmount,
                _groupId
            );
    }

    /**
     * @notice updates postionSize and quoteSize of the trader and settle realizedPnl and updates base tokens.
     * Can only be called by oddz clearing house while removing liquidity
     * @param _positionId  position id
     * @param _takerBase   the base token amount
     * @param _takerQuote  the quote token amount
     * @param _realizedPnl realized PnL
     */
    function settleBalanceAndDeregister(
        uint256 _positionId,
        int256 _takerBase,
        int256 _takerQuote,
        int256 _realizedPnl
    ) external override onlyClearingHouse {
        //updates the position info
        _updateTraderPositionInfo(
            traderPositionInfo[_positionId].trader,
            traderPositionInfo[_positionId].baseToken,
            _positionId,
            _takerBase,
            _takerQuote,
            traderPositionInfo[_positionId].groupID
        );

        // to avoid dust, let realizedPnl = getQuote() when there's no position
        if (getTakerBasePositionSize(_positionId) == 0) {
            // only need to take care of taker's accounting when there's no position
            int256 takerQuoteAmount = traderPositionInfo[_positionId]
                .takerQuoteSize;

            require(_realizedPnl.abs() <= takerQuoteAmount.abs(), "BalanceManager:Inconsistent quote balance and realizedPnL");

            _realizedPnl = takerQuoteAmount;
        }
        _settleQuoteToOwedRealizedPnl(_positionId, _realizedPnl);
        _updateTraderPositions(traderPositionInfo[_positionId].trader, _positionId, 0, false, false, false);
        // _updateBaseTokensForTrader(_maker, _baseToken, false);
    }

    /**
     * @notice updates and settles Pnl in the main collateral Balance.It is called by clearing House when removing liquidity.
     * @param _maker       maker address
     * @param _quoteAmount       maker's difference in provided amount and recieved amount
     * @param _swappedQuoteSize  quote amount, we got/spent when closing the impermanent position.
     * @param _closing           if we are closing the impermanent position or not
     */
    function settleLiquidityPnL(
        address _maker,
        int256 _quoteAmount,
        int256 _swappedQuoteSize,
        bool _closing
    ) external override onlyClearingHouse {
        if (_closing) {
            int256 OwedPnl;

            //if quoteAmount is positive that means it was a short position. so to close this swap quote -> base.so swappedQuoteSize will be negative
            //if quoteAMount is negative that means it was a long position. so to close this swap base -> quote.swappedQuoteSize will be positive
            // so adding both of them will give PnL
            OwedPnl = _quoteAmount.add(_swappedQuoteSize);

            IOddzVault(oddzVault).updateCollateralBalance(_maker, OwedPnl);
        } else {
            IOddzVault(oddzVault).updateCollateralBalance(_maker, _quoteAmount);
        }
    }

    /**
     * @notice update insurance fund fees
     * @param _amount The owned fee amount 
     */
    function updateInsuranceManagerFees(int256 _amount) external override onlyClearingHouse {
       if (_amount != 0) {
            IOddzVault(oddzVault).updateCollateralBalance(
                insuranceManager,
                _amount
            );
        }
        emit updatedInsuranceFee(_amount);
    }

     /**
    * @notice udpates the liquidation fees
    * @param _liquidator liquidator address
    * @param _trader     trader address
    * @param _amount      swapped quote position amount
     */
    function updateLiquidationFees(address _liquidator,address _trader,int256 _amount) external override onlyClearingHouse{
        uint256 liquidationFee =
            _amount.abs().mulRatio(
                IOddzConfig(oddzConfig).liquidationPenaltyRatio()
            );
        
        IOddzVault(oddzVault).updateCollateralBalance(
                _trader,
                liquidationFee.neg256()
            );
        
        IOddzVault(oddzVault).updateCollateralBalance(
                _liquidator,
                liquidationFee.toInt256()
            );
    }

    /**
     * @notice Settles quote amount into owedRealized profit or loss.Can only be called by Oddz clearing house
     * @param _positionId       position id
     * @param _settlementAmount the amount to be settled
     */
    function settleQuoteToOwedRealizedPnl(
        uint256 _positionId,
        int256 _settlementAmount
    ) external override onlyClearingHouse {
        _settleQuoteToOwedRealizedPnl(_positionId, _settlementAmount);
    }

    /**	
     * @notice updates owed realized PnL.	
     * @param _positionId        Position id	
     * @param _amount            amount to be realized	
     */	
    function updateOwedRealizedPnl(uint256 _positionId, int256 _amount)	
        external	
        override	
        onlyClearingHouse	
    {	
        if (_amount != 0) {	
            traderPositionInfo[_positionId]	
                .owedRealizedPnl = traderPositionInfo[_positionId]	
                .owedRealizedPnl	
                .add(_amount);	
            emit PnlRealized(_positionId, _amount);	
        }	
    }	
    /**	
     *@notice updates the time weighted premium of the position after settling funding payment	
     *@param _positionId position id	
     *@param _twPremiumGrowthGlobal time weighted premium	
     */	
    function updateTwPremiumGrowthGlobal(	
        uint256 _positionId,	
        int256 _twPremiumGrowthGlobal	
    ) external override onlyClearingHouse {	
        traderPositionInfo[_positionId]	
            .lastTwPremiumGrowthGlobalX96 = _twPremiumGrowthGlobal;	
    }

    /**
    * @notice to get position collateral value (collateral + unrealizedPnl+realizedPnl - pending funding payment )
    * @param _positionId position id
    * @return _positionCollateralValue position collateral value 
     */
    function getPositionCollateralValue(uint256 _positionId)
        public
        view 
        override
        returns(int256 _positionCollateralValue) 
    {
        int256 pendingFunding=ISwapManager(swapManager).getPositionPendingFundingPayment(_positionId);
        int256 unrealizedPnl=getPositionUnrealisedPnL(_positionId);
        int256 collateralBalance_18=(traderPositionInfo[_positionId].collateralForPosition*(10**(18 - IOddzVault(oddzVault).settlementTokenDecimals()))).toInt256();
        _positionCollateralValue=collateralBalance_18.add(traderPositionInfo[_positionId].owedRealizedPnl).sub(pendingFunding).add(unrealizedPnl);
    }

     /**
    * @notice to get group collateral value (collateral + unrealizedPnl+realizedPnl - pending funding payment )
    * @param _groupId group id
    * @return _groupCollateralValue group collateral value 
     */
    function getGroupCollateralValue(uint256 _groupId)
        public
        view 
        override
        returns(int256 _groupCollateralValue) 
    {
        IBalanceManager.GroupInfo memory gInfo=groupInfo[_groupId];
        for(uint256 i=0;i<gInfo.groupPositions.length;i++){
            _groupCollateralValue=_groupCollateralValue.add(getPositionCollateralValue(gInfo.groupPositions[i].positionID));
        } 
        int256 collateralBalance_18=(gInfo.collateralAllocated*(10**(18 - IOddzVault(oddzVault).settlementTokenDecimals()))).toInt256();
        _groupCollateralValue=_groupCollateralValue.add(collateralBalance_18).add(gInfo.owedRealizedPnl);

    }

    /**
    * @notice to get liquidity collateral value (collateral + unrealizedPnl+realizedPnl - pending funding payment )
    * @param _orderId liquidity order id
    * @param _baseToken base token address
    * @return  _liquidityOrderValue liquidity order collteral value 
     */
    function getLiquidityOrderCollateralValue(bytes32 _orderId,address _baseToken)
        public
        view 
        override
        returns(int256 _liquidityOrderValue) 
    {
        IOrderManager.OrderInfo memory orderInfo=IOrderManager(orderManager).getCurrentOrderMap(_orderId);
        int256 pendingFunding=ISwapManager(swapManager).getLiquidityPositionPendingFundingPayment(_orderId,_baseToken);
        int256 unrealizedPnl=getLiquidityPositionUnrealisedPnL(_baseToken,_orderId);
        uint256 fees =IOrderManager(orderManager).fetchPendingFee(_orderId,_baseToken);
        int256 collateralBalance_18=(orderInfo.collateralForOrder*(10**(18 - IOddzVault(oddzVault).settlementTokenDecimals()))).toInt256();
        _liquidityOrderValue=collateralBalance_18.add(orderInfo.owedRealizedPnl).sub(pendingFunding).add(unrealizedPnl).add(fees.toInt256());
    }

    /**
    * @notice to get poisition value in usd
    * @param _positionId position id
    * @return _positionValue position value
    */

    function getPositionValue(uint256 _positionId)
        public
        view
        override
        returns(uint256 _positionValue)
    {
        IBalanceManager.PositionInfo memory positionInfo=traderPositionInfo[_positionId];
        uint256 indexPrice = _getBaseTokenIndexPrice(positionInfo.baseToken);
        // both position size and index price are in 18  decimals
        _positionValue=(positionInfo.takerBasePositionSize.mulDiv(indexPrice.toInt256(), 1e18)).abs();
    }

    /**
    * @notice to get group value in usd
    * @param _groupId position id
    * @return _groupValue position value
    */
    function getGroupValue(uint256 _groupId)
        public
        view
        override
        returns(uint256 _groupValue)
    {
        IBalanceManager.GroupInfo memory gInfo=groupInfo[_groupId];
        for(uint256 i=0;i<gInfo.groupPositions.length;i++){
            _groupValue=_groupValue.add(getPositionValue(gInfo.groupPositions[i].positionID));
        } 
    }

    /**
    * @notice to get liquidity order impermanent position value
    * @param _orderId order id
    * @param _baseToken base token address
    * @return _impermanentPositionValue impermanent position value
     */
    function getImpermanentPositionValue(bytes32 _orderId,address _baseToken)
        public
        view
        override
        returns(uint256 _impermanentPositionValue){
        uint256 currentTotalBaseTokenAmount =IOrderManager(orderManager).getCurrentTotalTokenAmountInPoolByOrderId(_baseToken,_orderId,true);
        uint256 totalBaseTokenDebt=IOrderManager(orderManager).getAmountInPoolByOrderId(_orderId,true);
        int256 makerImpermanentPositionBaseBalance = currentTotalBaseTokenAmount.toInt256().sub(totalBaseTokenDebt.toInt256());
        if(makerImpermanentPositionBaseBalance.abs()>_DUST){
            uint256 twapPrice = _getBaseTokenIndexPrice(_baseToken);
            _impermanentPositionValue= makerImpermanentPositionBaseBalance.mulDiv(twapPrice.toInt256(), 1e18).abs();
        }
    }

    /**
     * @notice to get base token amount of a position
     * @param _positionID       position id
     * @return _positionSize    base token amount
     */
    function getTakerBasePositionSize(uint256 _positionID)
        public
        view
        override
        returns (int256 _positionSize)
    {
        if (
            (traderPositionInfo[_positionID].takerBasePositionSize).abs() >=
            _DUST
        ) {
            _positionSize = traderPositionInfo[_positionID]
                .takerBasePositionSize;
        }
    }

    /**
     * @notice to get quote token amount of a position
     * @param _positionID       position id
     * @return _quoteSize    quote token amount
     */
    function getTakerQuoteSize(uint256 _positionID)
        external
        view
        override
        returns (int256 _quoteSize)
    {
        return traderPositionInfo[_positionID].takerQuoteSize;
    }

    /**
     * @notice It is used to get the total position debt value(usd) of the position
     * @param _positionID       position id
     * @return _positionDebt  Debt value(usd) of the position
     */
    function getTotalPositionDebt(uint256 _positionID)
        public
        view
        override
        returns (uint256 _positionDebt)
    {
        PositionInfo storage info = traderPositionInfo[_positionID];
        uint256 twapPrice = _getBaseTokenIndexPrice(info.baseToken);
        int256 totalBaseTokenValue = (info.takerBasePositionSize).mulDiv(
            twapPrice.toInt256(),
            1e18
        );
        if (info.takerQuoteSize >= 0) {
            return totalBaseTokenValue.abs();
        } else {
            //return (info.takerQuoteSize).add(totalBaseTokenValue).abs();
            return info.takerQuoteSize.abs();
        }
    }

    /**
     * @notice It is used to get the total value(usd) of  any group includes all the positions in the group
     * @param _groupId       group id
     * @return _groupSize   Value(usd) of the group
     */
    function getTotalGroupInfo(uint256 _groupId)
        external
        view
        override
        returns (uint256 _groupSize)
    {
        GroupInfo memory gInfo = groupInfo[_groupId];
        GroupPositionsInfo[] memory groupPositionsInfo = gInfo.groupPositions;
        for (uint256 i = 0; i < groupPositionsInfo.length; i++) {
            uint256 positionID = groupPositionsInfo[i].positionID;
            _groupSize = _groupSize.add(getTotalPositionDebt(positionID));
        }
    }

    /**
     * @notice It is used to get the total value(usd) of  any liqudity order
     * @param _baseToken    Base token address
     * @param _orderId      order id
     * @return _orderValue   Value(usd) of the order
     */
    function getTotalOrderInfo(address _baseToken, bytes32 _orderId)
        public
        view
        override
        returns (uint256 _orderValue)
    {
        IOrderManager.OrderInfo memory order = IOrderManager(orderManager)
            .getCurrentOrderMap(_orderId);
        uint256 twapPrice = _getBaseTokenIndexPrice(_baseToken);
        int256 totalBaseTokenValue = (order.baseAmountInPool.toInt256()).mulDiv(
            twapPrice.toInt256(),
            1e18
        );

        return
            (order.quoteAmountInPool.toInt256()).add(totalBaseTokenValue).abs();
    }

    /**	
     *@notice This function is used to get the  debt(total tokens in the pool) of the maker(liquidity provider)	
     *@param  _orderId order id of the liquidity position	
     *@return _orderDebt order debt	
     */	
    function getLiquidityOrderBaseDebt(bytes32 _orderId)	
        external	
        view	
        override	
        returns (int256 _orderDebt)	
    {	
        IOrderManager.OrderInfo memory order = IOrderManager(orderManager)	
            .getCurrentOrderMap(_orderId);	
        uint256 orderDebt = order.baseAmountInPool;	
        return orderDebt.neg256();	
    }

    /**
     * @notice used to get all the traders positions
     * @param _trader   trader address
     * @return _positions   all the position trader has
     */
    function getTraderPositions(address _trader)
        external
        view
        override
        returns (uint256[] memory _positions)
    {
        return traderPositions[_trader];
    }

    /**
     * @notice used to get all the traders groups
     * @param _trader   trader address
     * @return _groups   all the groups trader has
     */
    function getTraderGroups(address _trader)
        external
        view
        override
        returns (uint256[] memory _groups)
    {
        return traderGroups[_trader];
    }

    /**
     * @notice used to get  group information
     * @param _groupId  group id
     * @return _info   info of the group
     */
    function getGroupInfo(uint256 _groupId)
        external
        view
        override
        returns (GroupInfo memory _info)
    {
        return groupInfo[_groupId];
    }

    /**
     * @notice used to get  position information
     * @param _positionId  position id
     * @return _info   info of the position
     */
    function getPositionInfo(uint256 _positionId)
        external
        view
        override
        returns (PositionInfo memory _info)
    {
        return traderPositionInfo[_positionId];
    }

    /**
     * @notice used to get  total collateral used in position
     * @param _trader  trader address
     * @return _collateral   collateral used in position for the trader
     */
    function getTotalUsedCollateralInPositions(address _trader)
        external
        view
        override
        returns (uint256 _collateral)
    {
        return totalUsedCollateralInPositions[_trader];
    }

    /**
     * @notice used to get  default group of if the trader
     * @param _trader  trader address
     * @return _defaultGroupId  default group id for the trader
     */
    function getDefaultGroupForTrader(address _trader)
        external
        view
        override
        returns(uint256 _defaultGroupId){
            return traderDefaultGroup[_trader];
        }

    /**
    * @notice to get maintenance margin requirement for position
    * @param _positionId position id
    * @return _marginRequired margin required for the position
     */
     function getMarginRequirementForPositionLiquidation(uint256 _positionId) 
        external
        view
        override
        returns(int256 _marginRequired){
            
            return getPositionValue(_positionId).mulRatio(IOddzConfig(oddzConfig).maintenanceMarginRatio()).toInt256();
     }

     /**
    * @notice to get maintenance margin requirement for group
    * @param _groupId group id
    * @return _marginRequired margin required for the group
     */
     function getMarginRequirementForGroupLiquidation(uint256 _groupId) 
        external
        view
        override
        returns(int256 _marginRequired){
            
            return getGroupValue(_groupId).mulRatio(IOddzConfig(oddzConfig).maintenanceMarginRatio()).toInt256();
     }

     /**
    * @notice to get maintenance margin requirement for liquidity order
    * @param _orderId order id
    * @param _baseToken baseToken address
    * @return _marginRequired margin required for the group
     */
     function getMarginRequirementForLiquidityOrderLiquidation(bytes32 _orderId,address _baseToken) 
        external
        view
        override
        returns(int256 _marginRequired){
            
            return getImpermanentPositionValue(_orderId,_baseToken).mulRatio(IOddzConfig(oddzConfig).maintenanceMarginRatio()).toInt256();
     }

    

    /**
     * @notice Used to update positions id and collateral of a trader
     * @param _trader Address of the trader
     * @param _positionID position id
     * @param _collateralForPosition collateral used in position
     * @param _existing   if the position id already exist or not
     * @param _group     if position is in any group or not
     * @param _push       true if we want to add the position and false if we want to remove position
     */
    function _updateTraderPositions(
        address _trader,
        uint256 _positionID,
        uint256 _collateralForPosition,
        bool _existing,
        bool _group,
        bool _push
    ) internal  {
        if (_push) {
            //checks if position is existing or not.
            if (!_existing) {
                //push the id in the array
                traderPositions[_trader].push(_positionID);
                positionIndex[_positionID]=traderPositions[_trader].length-1;
            }
            //If position is not in the group , then collateral will be stored in position info .Otherwise in group Info
            if (!_group) {
                traderPositionInfo[_positionID]
                    .collateralForPosition = traderPositionInfo[_positionID]
                    .collateralForPosition
                    .add(_collateralForPosition);
            }
            // this variable does not depend on whether position is in group or not
            totalUsedCollateralInPositions[
                _trader
            ] = totalUsedCollateralInPositions[_trader].add(
                _collateralForPosition
            );
        } else {
            PositionInfo memory positionInfo = traderPositionInfo[_positionID];

            // if position holds balances ,it can not be deleted
            if (
                positionInfo.takerBasePositionSize.abs() >= _DUST ||
                positionInfo.takerQuoteSize.abs() >= _DUST
            ) {
                return;
            } else {
                //if the position is not in the group then update the position as isolate position
                if (!_group) {
                    uint256 collateralAllocatedForPosition = traderPositionInfo[
                        _positionID
                    ].collateralForPosition;

                    ///update the owed realized PnL in vault Balance
                    IOddzVault(oddzVault).updateCollateralBalance(
                        _trader,
                        traderPositionInfo[_positionID].owedRealizedPnl
                    );
                    totalUsedCollateralInPositions[
                        _trader
                    ] = totalUsedCollateralInPositions[_trader].sub(
                        collateralAllocatedForPosition
                    );
                    delete traderPositionInfo[_positionID];
                    uint256[] storage allPositions = traderPositions[_trader];
                    uint256 positionsLength = allPositions.length;
                    uint index=positionIndex[_positionID];
                    if(index!=positionsLength-1){
                         allPositions[index]=allPositions[positionsLength-1];
                         positionIndex[allPositions[index]]=index;
                    }
                    allPositions.pop();
                    delete positionIndex[_positionID];
                }
            }
        }
    }
    
    
    /** @notice used to get trader PnL(Unrealised and Realised).
     * @param _trader  address of the trader.
     * @param _isIsolate true for isolated position and false for grouping
     * @return _unrealizedPnL returns unrealized Pnl of either all isolate poistion or grouped positions
     * @return _realizedPnL return realized PnL of either all isolate poistion or grouped positions
     */
    function getTraderPnLBy(address _trader, bool _isIsolate) public override view returns(int256 _unrealizedPnL, int256 _realizedPnL){

        // if _isIsolate true, will provide trader isolated pnl. 
        // if _isIsolate false, will provide trader grouped pnl. 
        if(_isIsolate){
            uint256[] memory positions = traderPositions[_trader];
            for (uint j = 0; j < positions.length; j++){
                if (traderPositionInfo[positions[j]].groupID == 0) {
                    uint256 positionID = positions[j];
                    // get unrealised pnl position id wise
                    _unrealizedPnL = _unrealizedPnL.add(getPositionUnrealisedPnL(positionID));
                    _realizedPnL =_realizedPnL.add(traderPositionInfo[positions[j]].owedRealizedPnl);
                }
            }
        } else {
            /*
            // If position is opened in group then group id must be greater than zero.  
            Example :- suppose,
            If there are two groups of trader
            group 1 unrealised pnl : -197442795627896128
            group 2 unrealised pnl : -229119237059084392
            grouped unrealised pnl : (-197442795627896128-229119237059084392)
                                   :-426562032686980520
            // Similiarly for realised pnl.
            */
            uint256[] memory groupIds = traderGroups[_trader];
            for (uint256 i = 0; i < groupIds.length; i++){
                uint256 groupId = groupIds[i];
                if (groupId  > 0) {
                    (int256 unrealizedPnLByID, int256 realizedPnLByID)  = getGroupPnL(
                                                                             groupId
                                                                            );
                    
                    _realizedPnL = _realizedPnL.add(realizedPnLByID).add(groupInfo[groupId]
                                                                        .owedRealizedPnl);
                    
                    _unrealizedPnL = _unrealizedPnL.add(unrealizedPnLByID);
                }
            }
        }
        
    }
    
    /**
     * @notice used to get trader's group PnL .
     * @param _groupId  group id 
     * @return _unrealizedPnL unrealized Pnl of the group
     * @return _realizedPnl unrealized PnL of the group
     */
    function getGroupPnL(uint256 _groupId) public override view returns(int256 _unrealizedPnL, int256 _realizedPnl){
        // get group info using group id.
        GroupInfo memory gpInfo = groupInfo[_groupId];
        // get group position  ids in particular group. 
        GroupPositionsInfo[] memory groupPositionsInfo = gpInfo.groupPositions;
        for (uint256 j = 0; j < groupPositionsInfo.length; j++) {
            uint256 positionID = groupPositionsInfo[j].positionID;
            /*
            If there are two position in one groups of trader
            add all position ids pnl.
            position 1 realised pnl : -5989926349946458
            position 2 realised pnl : -5990999367204384
            grouped unrealised pnl : (-5989926349946458-5990999367204384)
                                   :-11980925717150842
            */
            _unrealizedPnL = _unrealizedPnL.add(getPositionUnrealisedPnL(positionID));
            _realizedPnl = _realizedPnl.add(traderPositionInfo[positionID].owedRealizedPnl);
        }
        
    }


     /**
     * @notice used to get unrealised PnL.
     * @param _positionID  position id 
     * @return _unrealizedPnl unrealized PnL of the position
     */
    function getPositionUnrealisedPnL(uint256 _positionID) public override view returns(int256 _unrealizedPnl){
        int256 totalBasePositionValue;
        int256 totalQuotePositionValue; 
        
        totalBasePositionValue = totalBasePositionValue.add(getBaseTokenValue(_positionID));
    
        totalQuotePositionValue = traderPositionInfo[_positionID].takerQuoteSize;


         _unrealizedPnl = totalBasePositionValue.add(totalQuotePositionValue);
    }

      /**
     * @notice used to get unrealised PnL of liquidity position by order id.
     * @param _baseToken base token address
     * @param _orderId  order id 
     * @return _unrealizedPnL unrealized Profit or loss from liquidity position
     */
    function getLiquidityPositionUnrealisedPnL(address _baseToken,bytes32 _orderId) public override view returns(int256 _unrealizedPnL){
        int256 totalBaseTokenValue;
        int256 totalQuoteTokenValue;
        uint256 currentTotalBaseTokenAmount =IOrderManager(orderManager).getCurrentTotalTokenAmountInPoolByOrderId(_baseToken,_orderId,true);
        uint256 totalBaseTokenDebt=IOrderManager(orderManager).getAmountInPoolByOrderId(_orderId,true);
        int256 makerImpermanentPositionBaseBalance = currentTotalBaseTokenAmount.toInt256().sub(totalBaseTokenDebt.toInt256());
        if(makerImpermanentPositionBaseBalance.abs()>_DUST){
            uint256 twapPrice = _getBaseTokenIndexPrice(_baseToken);
            totalBaseTokenValue= makerImpermanentPositionBaseBalance.mulDiv(twapPrice.toInt256(), 1e18);
        }
        uint256 currentTotalQuoteTokenAmount =IOrderManager(orderManager).getCurrentTotalTokenAmountInPoolByOrderId(_baseToken,_orderId,false);
        uint256 totalQuoteTokenDebt=IOrderManager(orderManager).getAmountInPoolByOrderId(_orderId,false);
        totalQuoteTokenValue= currentTotalQuoteTokenAmount.toInt256().sub(totalQuoteTokenDebt.toInt256());
        _unrealizedPnL=totalBaseTokenValue.add(totalQuoteTokenValue);
    }

    /**
     * @notice used to get trader total unrealised PnL of liquidity position.
     * @param _trader address of trader.
     * @return _unrealisedPnL unrealized Profit or loss from liquidity position
     */
    function getTraderTotalLiquidityUnrealisedPnL(address _trader) public override view returns(int256 _unrealisedPnL){
        address[] memory baseTokens = IOddzMarket(oddzMarket).addedMarket();
        for (uint256 i = 0; i < baseTokens.length; i++){
            address baseToken = baseTokens[i];
            bytes32[] memory _orderIds = IOrderManager(orderManager).getCurrentOrderIdsMap(_trader, baseToken);
            for (uint256 j = 0; j < _orderIds.length; j++){
                bytes32 orderId = _orderIds[j];
                _unrealisedPnL = _unrealisedPnL.add(getLiquidityPositionUnrealisedPnL(baseToken, orderId));
            }
        }
    }

    /**
     * @notice Used to update groups ,positions in groups and collateral of a trader
     * @param _trader Address of the trader
     * @param _baseToken base token address
     * @param _positionID position id
     * @param _groupID  group id
     * @param _collateralForPosition collateral used in position
     * @param _isNewGroup  is this a new group or existing
     * @param _existing   if the position id already exist or not
     * @param _push       true if we want to add the position and false if we want to remove position
     */
    function _updateTraderGroups(
        address _trader,
        address _baseToken,
        uint256 _positionID,
        uint256 _groupID,
        uint256 _collateralForPosition,
        bool _isNewGroup,
        bool _existing,
        bool _push
    ) internal {
        if (_push) {
            // is position does not already exist in group then push it in array
            if (!_existing) {
                GroupPositionsInfo[] storage groupPositions = groupInfo[
                    _groupID
                ].groupPositions;
                GroupPositionsInfo memory gpInfo = GroupPositionsInfo({
                    positionID: _positionID,
                    baseToken: _baseToken
                });
                groupPositions.push(gpInfo);

                // if default group then no limit on positions
                if (traderDefaultGroup[_trader] != _groupID) {
                    require(
                        groupPositions.length <=
                            IOddzConfig(oddzConfig).maxPositionsPerGroup(),
                        "BalanceManager:Max positions per group exceeded"
                    );
                }
            }
            groupInfo[_groupID].collateralAllocated = groupInfo[_groupID]
                .collateralAllocated
                .add(_collateralForPosition);

            // if it is new group then push it in the trader groups
            if (_isNewGroup) {
                traderGroups[_trader].push(_groupID);
                groupInfo[_groupID].trader = _trader;
            }
            if (traderDefaultGroup[_trader] != 0) {
                require(
                    traderGroups[_trader].length <=
                        IOddzConfig(oddzConfig).maxGroupsPerAccount(),
                    "BalanceManager:Max groups per account exceeded"
                );
            } else {
                require(
                    traderGroups[_trader].length.add(1) <=
                        IOddzConfig(oddzConfig).maxGroupsPerAccount(),
                    "BalanceManager:Max groups per account exceeded"
                );
            }
        } else {
            PositionInfo memory positionInfo = traderPositionInfo[_positionID];
            if (
                positionInfo.takerBasePositionSize.abs() >= _DUST ||
                positionInfo.takerQuoteSize.abs() >= _DUST
            ) {
                return;
            }
            GroupInfo storage gInfo;
            if (_groupID > 0) {
                gInfo = groupInfo[_groupID];
            }
            gInfo.owedRealizedPnl = gInfo.owedRealizedPnl.add(
                traderPositionInfo[_positionID].owedRealizedPnl
            );
            delete traderPositionInfo[_positionID];
            //updates the group position info
            _updatePositionsInGroup(_positionID, _groupID);

            uint256[] storage allPositions = traderPositions[_trader];
            uint256 positionsLength = allPositions.length;
            uint256 index = positionIndex[_positionID];
            if (index != positionsLength - 1) {
                allPositions[index] = allPositions[positionsLength - 1];
                positionIndex[allPositions[index]] = index;
            }
            allPositions.pop();
            delete positionIndex[_positionID];
        }
    }

    /**
    *@notice updates the position in the particular group
    *@param _positionID position id in the group 
    *@param _groupID group to be updated
     */
    function _updatePositionsInGroup(uint256 _positionID, uint256 _groupID)
        internal
    {
        GroupInfo storage gInfo = groupInfo[_groupID];

        GroupPositionsInfo[] storage groupPositions = gInfo.groupPositions;
        for (uint256 i = 0; i < groupPositions.length; i++) {
            if (groupPositions[i].positionID == _positionID) {
                if (i != groupPositions.length - 1) {
                    groupPositions[i] = groupPositions[
                        groupPositions.length - 1
                    ];
                }
                groupPositions.pop();
                break;
            }
        }
        if (groupPositions.length == 0) {
            // if group don;t have any positions make it inactive and settle owedRealizedPnl in the main collateral balance
            totalUsedCollateralInPositions[
                gInfo.trader
            ] = totalUsedCollateralInPositions[gInfo.trader].sub(
                gInfo.collateralAllocated
            );
            IOddzVault(oddzVault).updateCollateralBalance(
                gInfo.trader,
                gInfo.owedRealizedPnl
            );
            gInfo.collateralAllocated = 0;
            gInfo.owedRealizedPnl = 0;
        }
    }

    /**
     * @notice updates postionSize and quoteSize of the trader.Can only be called by oddz clearing house
     * @param _trader     address of the trader
     * @param _baseToken  base token address
     * @param _positionId  position id
     * @param _baseAmount the base token amount
     * @param _quoteAmount the quote token amount
     * @param _groupId     group id if position is in any group otherwise 0
     * returns updated values
     */
    function _updateTraderPositionInfo(
        address _trader,
        address _baseToken,
        uint256 _positionId,
        int256 _baseAmount,
        int256 _quoteAmount,
        uint256 _groupId
    ) internal returns (int256, int256) {
        PositionInfo storage info = traderPositionInfo[_positionId];
        info.trader = _trader;
        info.baseToken = _baseToken;
        info.takerBasePositionSize = info.takerBasePositionSize.add(
            _baseAmount
        );
        info.takerQuoteSize = info.takerQuoteSize.add(_quoteAmount);
        info.groupID = _groupId;

        return (info.takerBasePositionSize, info.takerQuoteSize);
    }
     /**
     * @notice used to get total value of base token of a particular position.
     * @param _positionID position id
     */
     function getBaseTokenValue(uint256 _positionID) public override view returns (int256) {
        /*
        Example:- suppose,
        takerBasePositionSize = 292039641190594
        twapPrice = 2828752930620000000000
        totalBasePositionValue = ((takerBasePositionSize *twapPrice) / 1000000000000000000)
                               = 824276046467627753
        */
        
        address baseToken = traderPositionInfo[_positionID].baseToken;
        
        int256 takerBasePositionSize;
        takerBasePositionSize = traderPositionInfo[_positionID]
                                    .takerBasePositionSize;
        
        int256 totalPositionSize = takerBasePositionSize;

        if (totalPositionSize.abs() < _DUST){
            return 0;
        }
        uint256 twapPrice = _getBaseTokenIndexPrice(baseToken);
        return totalPositionSize.mulDiv(twapPrice.toInt256(), 1e18);
     }


    /**
     * @notice Settles quote amount into owedRealized profit or loss
     * @param _positionId      position id
     * @param _settlementAmount the amount to be settled
     */
    function _settleQuoteToOwedRealizedPnl(
        uint256 _positionId,
        int256 _settlementAmount
    ) internal {
        PositionInfo storage info = traderPositionInfo[_positionId];
        info.takerQuoteSize = info.takerQuoteSize.sub(_settlementAmount);
        if (_settlementAmount != 0) {
            info.owedRealizedPnl = info.owedRealizedPnl.add(_settlementAmount);
        }
    }

    /**
     * @notice Fetch the price of the base token
     * @param _baseToken The Address of the base token
     * @return _twapPrice  of the base token
     */
    function _getBaseTokenIndexPrice(address _baseToken)
        internal
        view
        returns (uint256 _twapPrice)
    {
        return
            IIndexPrice(_baseToken).getBaseTokenIndexPrice(
                IOddzConfig(oddzConfig).twapInterval()
            );
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

interface IOddzConfig {
    /// @return _maxMarketsPerAccount Max value of total markets per account
    function maxMarketsPerAccount() external view returns (uint8 _maxMarketsPerAccount);

    /// @return _maxGroupsPerAccount Max value of total groups per account
    function maxGroupsPerAccount() external view returns (uint8 _maxGroupsPerAccount);
    
    /// @return _maxPositionsPerAccount Max value of total positions per account
    function maxPositionsPerAccount() external view returns (uint8 _maxPositionsPerAccount);
    
    /// @return _maxPositionsPerGroup Max value of total positions per group
    function maxPositionsPerGroup() external view returns (uint8 _maxPositionsPerGroup);

    /// @return _imRatio Initial margin ratio
    function initialMarginRatio() external view returns (uint24 _imRatio);

    /// @return _mmRatio Maintenance margin requirement ratio
    function maintenanceMarginRatio() external view returns (uint24 _mmRatio);

    /// @return _twapInterval TwapInterval for funding and prices (mark & index) calculations
    function twapInterval() external view returns (uint32 _twapInterval);

    /// @return _fundingRate funding rate
    function maxFundingRate() external view returns(uint24 _fundingRate);
    
    /// @return _insuranceFundFeeRatio of perticular base token.
    function insuranceFundFeeRatio(address _baseToken) external view returns(uint24 _insuranceFundFeeRatio);

    /// @return _partialCloseRatio partial close position ratio
    function partialCloseRatio() external view returns(uint24 _partialCloseRatio);

    /// @return _liquidationPenaltyRatio liquidity penalty ratio
    function liquidationPenaltyRatio() external view returns(uint24 _liquidationPenaltyRatio);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IOrderManager {
    /// @param liquidity          Liquidity amount
    /// @param lowerTick          Lower tick of liquidity range
    /// @param upperTick          Upper tick of liquidity range
    /// @param lastFeeGrowthInside  lastFeeGrowthInside fees in quote token recorded in swap maanger
    /// @param baseAmountInPool   number of base token added
    /// @param quoteAmountInPool  number of quote token added
    /// @param collateralForOrder collateral allocated for this order
    /// @param lastTwPremiumGrowthInsideX96 time weighted premium growth inside
    /// @param lastTwPremiumGrowthBelowX96   time weighted premium growth below
    /// @param lastTwPremiumDivBySqrtPriceGrowthInsideX96 time weighted premium growth inside div by sqrt price
    /// @param owedRealizedPnl  owed realized Pnl
    /// @param lastTwPremiumGrowthGlobalX96  the last time weighted premiumGrowthGlobalX96
    struct OrderInfo {
        address trader;
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
        uint256 lastFeeGrowthInside;
        uint256 baseAmountInPool;
        uint256 quoteAmountInPool;
        uint256 collateralForOrder;
        int256 lastTwPremiumGrowthInsideX96;
        int256 lastTwPremiumGrowthBelowX96;
        int256 lastTwPremiumDivBySqrtPriceGrowthInsideX96;
        int256 owedRealizedPnl;
        int256 lastTwPremiumGrowthGlobalX96; 
    }

    /// @param trader                   Trader address
    /// @param baseToken                Base token address
    /// @param baseAmount               Base token amount
    /// @param quoteAmount              Quote token amount
    /// @param lowerTickOfOrder         Lower tick of liquidity range
    /// @param upperTickOfOrder         Upper tick of liquidity range
    /// @param twPremiumX96              time weighted premium  
    /// @param twPremiumDivBySqrtPriceX96 time weighted premium div by sqrt price
    struct AddLiquidityParams {
        address trader;
        address baseToken;
        uint256 baseAmount;
        uint256 quoteAmount;
        int24 lowerTickOfOrder;
        int24 upperTickOfOrder;
        uint256 collateralForOrder;
        int256 twPremiumX96;
        int256 twPremiumDivBySqrtPriceX96;
    }

    /// @param baseAmount         The amount of base token added to the pool
    /// @param quoteAmount        The amount of quote token added to the pool
    /// @param liquidityAmount    The amount of liquidity recieved from the pool
    /// @param feeAmount          fees accured after adding liquidity.
    /// @param orderId            Order id for this liquidity position
    struct AddLiquidityResponse {
        uint256 baseAmount;
        uint256 quoteAmount;
        uint128 liquidityAmount;
        uint256 feeAmount;
        bytes32 orderId;
    }

    /// @param trader                  Trader Address
    /// @param baseToken               Base token address
    /// @param lowerTickOfOrder        Lower tick of liquidity range
    /// @param upperTickOfOrder        Upper tick of liquidity range
    /// @param liquidityAmount         Amount of liquidity you want to remove
    struct RemoveLiquidityParams {
        address trader;
        address baseToken;
        int24 lowerTickOfOrder;
        int24 upperTickOfOrder;
        uint128 liquidityAmount;
    }

    /// @param baseAmount       The amount of base token removed from the pool
    /// @param quoteAmount      The amount of quote token removed from the pool
    /// @param feeAmount        fees accured after removing liquidity.
    /// @param takerBaseAmount  The base amount which is different from what had been added
    /// @param takerQuoteAmount The quote amount which is different from what had been added
    /// @param orderId          order id for this liquidity position
    struct RemoveLiquidityResponse {
        uint256 baseAmount;
        uint256 quoteAmount;
        uint256 feeAmount;
        int256 takerBaseAmount;
        int256 takerQuoteAmount;
        bytes32 orderId;
    }

    /// @param baseToken               Base token address
    /// @param isShort                 True for opening short position,false for long
    /// @param shouldUpdateState       Update the state is true
    /// @param specifiedAmount         Amount entered by trader
    /// @param sqrtPriceLimitX96       Price limit same as uniswap V3
    /// @param swapFees             Uniswap fee will be ignored and use the swapFees instead
    /// @param uniswapFee              UniswapFee cache only
    /// @param twPremiumX96 updated time weighted premium
    /// @param twPremiumDivBySqrtPriceX96 updated time weighted premium div by sqrt price
    struct rSwapParams {
        address baseToken;
        bool isShort;
        bool shouldUpdateState;
        int256 specifiedAmount;
        uint160 sqrtPriceLimitX96;
        uint24 swapFees;
        uint24 uniswapFee;
        int256 twPremiumX96;
        int256 twPremiumDivBySqrtPriceX96;
    }

    /// @param tick       cureent tick 
    /// @param fee        fee will be charged.
    struct rSwapResponse {
        int24 tick;
        uint256 fee;
        uint256 insuranceFee;
    }

    struct MintCallbackData {
        address trader;
        address pool;
    }

    struct ReplaySwapParams {
        address baseToken;
        bool isShort;
        bool shouldUpdateState;
        int256 amount;
        uint160 sqrtPriceLimitX96;
        uint24 swapFees;
        uint24 uniswapFee;
    }

    struct ReplaySwapResponse {
        int24 tick;
        uint256 fee;
    }

    struct InternalSwapStep {
        uint160 initialSqrtPriceX96;
        int24 nextTick;
        bool isNextTickInitialized;
        uint160 nextSqrtPriceX96;
        uint256 amountIn;
        uint256 amountOut;
        uint256 fee;
    }

    /// @notice this event is emitted when Pnl is realized for any liquidity order
    /// @param orderId order id
    /// @param amount pnl amount
    event PnlRealized(
        bytes32 orderId,
        int256 amount
    );


    /// @notice Add liquidity logic
    /// @dev Only used by `Oddz Clearing House` contract
    /// @param params Add liquidity params, detail on `IOrderManager.AddLiquidityParams`
    /// @return response Response of add liquidity
    function addLiquidity(AddLiquidityParams calldata params)
        external
        returns (AddLiquidityResponse memory response);

    /** @notice Remove liquidity logic, only used by `Oddz Clearing House` contract
    *@param params Remove liquidity params, detail on `IOrderManager.RemoveLiquidityParams`
    *@return response Response of remove liquidity
     */ 
    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (RemoveLiquidityResponse memory response);


    /** @notice This function is used to update the fundin payment of the order
    *   @param orderId order id
    *   @param amount funding amount
    */
    function updateLiquidityPositionOwedRealizedPnl(bytes32 orderId, int256 amount)
        external;

    /**@notice used to update funding growth variables for liquidity order and calculate liquidity coefficient
    * @param baseToken base token address
    * @param orderId order id
    * @param twPremiumX96 updated time weighted premium
    * @param twPremiumDivBySqrtPriceX96 updated time weighted premium div by sqrt price
    * @return liquidityCoefficientInFundingPayment liquidity coefficient value in funding payment
     */
    function updateFundingGrowthAndLiquidityCoefficientInFundingPayment(
        address baseToken,
        bytes32 orderId,
        int256 twPremiumX96,
        int256 twPremiumDivBySqrtPriceX96
    )external returns (int256 liquidityCoefficientInFundingPayment);

    
    /** @notice used to udpate the time weighted premium value of a liquidity position
    * @param orderId order id
    * @param twPremiumGrowthGlobalX96 new time weighted premium growth
     */
    function updateTwPremiumGrowthGlobal(
        bytes32 orderId,
        int256 twPremiumGrowthGlobalX96
    ) external;

    /** @notice Used to get all the order ids of the trader for that market
    * @param trader User address
    * @param baseToken base token address
    * @return orderIds all the order id of the user
    */
    function getCurrentOrderIdsMap(address trader, address baseToken)
        external
        view
        returns (bytes32[] memory orderIds);

    /** @notice Used to get all the order amounts in the pool
    * @param trader User address
    * @param baseToken base token address
    * @param base if true only include base token amount in pool otherwise only include quote token amount in pool
    * @return amountInPool Gives the total amount of a particular token in the pool for the user
    */
    function getTotalOrdersAmountInPool(
        address trader,
        address baseToken,
        bool base
    ) external view returns (uint256 amountInPool);


    /** @notice used to get total token amount in uniswap pool for particular liquidity order
    * @param orderId order id
    * @param base  true if want base amount , false if quote
    * @return orderAmount total Order amount(base or quote)
    */
    function getAmountInPoolByOrderId(bytes32 orderId, bool base)
        external
        view
        returns (uint256 orderAmount);

    /**
     * @notice Calculates current token amount inside the specific pool of uniswapV3Pool for a trader
     * @param baseToken base token address
     * @param orderId order id
     * @param base  true: get base amount, false: get quote amount
     * @return tokenAmountInPool returns all token inside pool amount for a particular token
     */
    function getCurrentTotalTokenAmountInPoolByOrderId(
        address baseToken,
        bytes32 orderId,
        bool base
    ) external view returns (uint256 tokenAmountInPool);

    /**
     *@notice  to get the total collateral used in orders
     *@param trader address of the trader
     *@return collateral total collateral
     */
    function getTotalCollateralForOrders(address trader)
        external
        view
        returns (uint256 collateral);

    /**
     *@notice  to get the info of the order
     *@param orderId order is of the liquidity position
     *@return info order info
     */
    function getCurrentOrderMap(bytes32 orderId)
        external
        view
        returns (OrderInfo memory info);

    /**@notice used to get liquidity coefficient
    * @param baseToken base token address
    * @param orderId order id
    * @param twPremiumX96 updated time weighted premium
    * @param twPremiumDivBySqrtPriceX96 updated time weighted premium div by sqrt price
    * @return liquidityCoefficientInFundingPayment liquidity coefficient value in funding payment
    */
    function getLiquidityCoefficientInFundingPayment(
        address baseToken,
        bytes32 orderId,
        int256 twPremiumX96,
        int256 twPremiumDivBySqrtPriceX96
    ) external view  returns (int256 liquidityCoefficientInFundingPayment);

    /**
     * @notice Calculates unique order ID
     * @param trader Address of the trader
     * @param baseToken Base token Address
     * @param lowerTick  Lower tick of liquidity range
     * @param upperTick  Upper tick of liquidity range
     * @return bytes32 unique hash/ID of that order
     */
    function calcOrderID(
        address trader,
        address baseToken,
        int24 lowerTick,
        int24 upperTick
    ) external pure returns (bytes32);

    function rSwap(
        rSwapParams memory params
    ) external  returns (rSwapResponse memory); 
    
    function fetchPendingFee(
       bytes32 orderId, address baseToken
    ) external view returns (uint256 totalPendingFee);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IOddzMarket {

    struct MarketData {
        address pool;
        uint24 uniswapFee;
    }

     /// @notice Get the pool address (UNIv3 pool) by given base token address
    /// @param baseToken The address of the base token
    /// @return pool The address of the pool
    function fetchPool(address baseToken) external view returns (address pool);

    /// @notice Get max allowed orders per market
    /// @return maxOrdersPerMarket The max allowed orders per market
    function getMaxOrdersPerMarket() external view returns (uint8 maxOrdersPerMarket);

    /**
    * @notice This is the view function which returns the market data.
    * @param _bToken tokenA One of the two tokens in the desired pool
    * @return _data market data of pool and various fees.
    */
    function fetchMarketData(address _bToken) external view returns (MarketData memory _data) ;

    
    /**
    * @notice get total market added.
    */
    function addedMarket() external view returns (address[] memory);

    /**
    * @notice update the swap fee, initially swap fee will 0.2%.
    * @param _bToken tokenA One of the two tokens in the desired pool
    * @param _feeRatio ratio should be updated to.
    */
    function updateSwapFee(address _bToken, uint24 _feeRatio) external;

    
    function fetchVolumeRange(address _bToken, uint8 _id) external view returns (uint256);

    /**
    * @notice this function used to provide swap fee.
    * @param _trader address of trader.
    * @param _bToken address of the base token
    */    
    function fetchSwapFee(address _trader, address _bToken) external view returns(uint24);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IIndexPrice {
    /// @notice Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    /// @return indexPrice Twap price with interval
    function getBaseTokenIndexPrice(uint256 interval) external view returns (uint256 indexPrice);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IBalanceManager {
    struct PositionInfo {
        address trader; // address of the trader
        address baseToken; // base token address
        uint256 groupID; // group id if position is in group otherwise 0 (group id starts from 1)
        int256 takerBasePositionSize; //trader base token amount
        int256 takerQuoteSize; //trader quote token amount
        uint256 collateralForPosition; // allocated collateral for this position
        int256 owedRealizedPnl; // owed realized profit and loss
        int256 lastTwPremiumGrowthGlobalX96; // the last time weighted premiumGrowthGlobalX96
    }

    struct GroupPositionsInfo {
        uint256 positionID; // position id
        address baseToken; // base token of the position
    }

    struct GroupInfo {
        address trader; // address of the trader
        bool autoLeverage;  // if for this group auto leverage is enabled or not .
        uint256 collateralAllocated; // collateral allocated to this group
        int256 owedRealizedPnl; // owed realized profit and loss
        GroupPositionsInfo[] groupPositions; // all the positions this group holds
    }

    /* /// @notice Every time a trader's position value is checked, the base token list of this trader will be traversed;
    /// thus, this list should be kept as short as possible
    /// @dev Only used by `ClearingHouse` contract
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    ///@param include true if token is going to be added otherwise false
    function updateBaseTokensForTrader(
        address trader,
        address baseToken,
        bool include
    ) external; */

      /**
     * @notice Used to set the default group id for the trader
     * @param trader Address of the trader
     * @param id default group id
     */
    function updateTraderDefaultGroupID(
        address trader,
        uint256 id
        )external ;

    /**
     * @notice Used to update positions id and collateral of a trader
     * @param trader Address of the trader
     * @param positionID position id
     * @param collateralForPosition collateral used in position
     * @param existing   if the position id already exist or not
     * @param group     if position is in any group or not
     * @param push       true if we want to add the position and false if we want to remove position
     */
    function updateTraderPositions(
        address trader,
        uint256 positionID,
        uint256 collateralForPosition,
        bool existing,
        bool group,
        bool push
    ) external;

    /**
     * @notice Used to update groups ,positions in groups and collateral of a trader
     * @param trader Address of the trader
     * @param baseToken base token address
     * @param positionID position id
     * @param groupID  group id
     * @param collateralForPosition collateral used in position
     * @param isNewGroup  is this a new group or existing
     * @param existing   if the position id already exist or not
     * @param push       true if we want to add the position and false if we want to remove position
     */
    function updateTraderGroups(
        address trader,
        address baseToken,
        uint256 positionID,
        uint256 groupID,
        uint256 collateralForPosition,
        bool isNewGroup,
        bool existing,
        bool push
    ) external;

     /**
     *@notice This function updates the group and position info for the trader.
     *@dev Is called by oddz Clearing house when moving positions
     *@param positionID position id
     *@param groupPositionID position id of the group to which position is going to merge
     *@param groupID  group id of the destination position
     *@param sourceRealizedPnL realized PnL of the source position
     *@param sourceGroupID group id of the source position
     *@param collateral  collateral allocated
     *@param merge if two positions are merged or not
     */
    function updateTraderGroupAndPosition(
        uint256 positionID,
        uint256 groupPositionID,
        uint256 groupID,
        int256 sourceRealizedPnL,
        uint256 sourceGroupID,
        uint256 collateral,
        bool merge
    ) external ;


    /**
    *@notice updates the collateral amount of the position
    *@param positionID position id in the group 
    *@param collateral collateral amount
     */
     function updateCollateral(
        uint256 positionID,
        uint256 collateral
    )external;

    /**
    *@notice updates the position in the particular group
    *@param positionID position id in the group 
    *@param groupID group to be updated
     */
    function updatePositionsInGroup(
        uint256 positionID,
        uint256 groupID
        )external ;

    /**
     * @notice updates postionSize and quoteSize of the trader.Can only be called by oddz clearing house
     * @param trader     address of the trader
     * @param baseToken  base token address
     * @param positionId  position id
     * @param baseAmount the base token amount
     * @param quoteAmount the quote token amount
     * @param groupId     group id if position is in any group otherwise 0
     * returns updated values
     */
    function updateTraderPositionInfo(
        address trader,
        address baseToken,
        uint256 positionId,
        int256 baseAmount,
        int256 quoteAmount,
        uint256 groupId
    ) external returns (int256, int256);

    /**
     * @notice updates postionSize and quoteSize of the trader and settle realizedPnl and updates base tokens.
     * Can only be called by oddz clearing house while removing liquidity
     * @param _positionId  position id
     * @param _takerBase   the base token amount
     * @param _takerQuote  the quote token amount
     * @param _realizedPnl realized PnL
     */
    function settleBalanceAndDeregister(
        uint256 _positionId,
        int256 _takerBase,
        int256 _takerQuote,
        int256 _realizedPnl
    ) external;


    /**
     * @notice Settles quote amount into owedRealized profit or loss.Can only be called by Oddz clearing house
     * @param positionId       position id
     * @param settlementAmount the amount to be settled
     */
    function settleQuoteToOwedRealizedPnl(
        uint256 positionId,
        int256 settlementAmount
    ) external;

    /**
     * @notice updates and settles Pnl in the main collateral Balance.It is called by clearing House when removing liquidity. 
     * @param maker       maker address
     * @param quoteAmount       maker's difference in provided amount and recieved amount
     * @param swappedQuoteSize  quote amount, we got/spent when closing the impermanent position
     * @param closing           if we are closing the impermanent position or not
     */
    function settleLiquidityPnL(
        address maker,
        int256 quoteAmount,
        int256 swappedQuoteSize,
        bool closing
    ) external;

    /**
     * @notice update insurance fund fees
     * @param _amount The owned fee amount 
     */
    function updateInsuranceManagerFees(int256 _amount) external;

    /**
    * @notice udpates the liquidation fees
    * @param liquidator liquidator address
    * @param trader     trader address
    * @param amount      swapped quote position amount
     */
    function updateLiquidationFees(address liquidator,address trader,int256 amount) external;


    /**
     * @notice updates owed realized PnL.
     * @param positionId        Position id
     * @param amount            amount to be realized
     */
    function updateOwedRealizedPnl(uint256 positionId, int256 amount) external;

    /**
     *@notice updates the time weighted premium of the position after settling funding payment
     *@param positionId position id
     *@param twPremiumGrowthGlobal time weighted premium
     */
    function updateTwPremiumGrowthGlobal(
        uint256 positionId,
        int256 twPremiumGrowthGlobal
    ) external;

    
    /**
    * @notice to get position value
    * @param positionId position id
    * @return positionCollateralValue position value (collateral + unrealizedPnl+realizedPnl + funding payment )
     */
    function getPositionCollateralValue(uint positionId)
        external
        view 
        returns(int256 positionCollateralValue); 
    
     /**
    * @notice to get group collateral value (collateral + unrealizedPnl+realizedPnl - pending funding payment )
    * @param groupId group id
    * @return groupCollateralValue group value 
     */
    function getGroupCollateralValue(uint256 groupId)
        external
        view 
        returns(int256 groupCollateralValue) ;

     /**
    * @notice to get liquidity collateral value (collateral + unrealizedPnl+realizedPnl - pending funding payment )
    * @param orderId liquidity order id
    * @param baseToken base token address
    * @return  liquidityOrderValue liquidity order collteral value 
     */
    function getLiquidityOrderCollateralValue(bytes32 orderId,address baseToken)
        external
        view 
        returns(int256 liquidityOrderValue);

     /**
    * @notice to get poisition value in usd (position size * index price)
    * @param positionId position id
    * @return positionValue position value
    */

    function getPositionValue(uint256 positionId)
        external
        view
        returns(uint256 positionValue);
    
     /**
    * @notice to get group value in usd
    * @param groupId position id
    * @return groupValue position value
    */
    function getGroupValue(uint256 groupId)
        external
        view
        returns(uint256 groupValue);
    
    /**
    * @notice to get liquidity order impermanent position value
    * @param orderId order id
    * @param baseToken base token address
    * @return impermanentPositionValue impermanent position value
     */
    function getImpermanentPositionValue(bytes32 orderId,address baseToken)
        external
        view
        returns(uint256 impermanentPositionValue);

    /**
     * @notice to get base token amount of a position
     * @param positionID       position id
     * @return positionSize    base token amount
     */
    function getTakerBasePositionSize(uint256 positionID)
        external
        view
        returns (int256 positionSize);

    /**
     * @notice to get quote token amount of a position
     * @param positionID       position id
     * @return quoteSize    quote token amount
     */
    function getTakerQuoteSize(uint256 positionID)
        external
        view
        returns (int256 quoteSize);

    /**
     * @notice It is used to get the total position debt value(usd) of the position
     * @param positionID       position id
     * @return totalPositionDebt  Debt value(usd) of the position
     */
    function getTotalPositionDebt(uint256 positionID)
        external
        view
        returns (uint256 totalPositionDebt);

    /**
     * @notice It is used to get the total value(usd) of  any group includes all the positions in the group
     * @param groupId       group id
     * @return groupValue   Value(usd) of the group
     */
    function getTotalGroupInfo(uint256 groupId)
        external
        view
        returns (uint256 groupValue);

    /**
     * @notice It is used to get the total value(usd) of  any liqudity order
     * @param baseToken    Base token address
     * @param orderId      order id
     * @return orderValue   Value(usd) of the order
     */
    function getTotalOrderInfo(address baseToken, bytes32 orderId)
        external
        view
        returns (uint256 orderValue);

    /**
    *@notice This function is used to get the  debt(total tokens in the pool) of the maker(liquidity provider)
    *@param  orderId order id of the liquidity position
    *@return orderDebt order debt
     */
    function getLiquidityOrderBaseDebt(bytes32 orderId)
        external
        view 
        returns(int256 orderDebt);

    /**
     * @notice used to get all the traders positions
     * @param trader   trader address
     * @return positions   all the position trader has
     */
    function getTraderPositions(address trader)
        external
        view
        returns (uint256[] memory positions);

    /**
     * @notice used to get all the traders groups
     * @param trader   trader address
     * @return groups   all the groups trader has
     */
    function getTraderGroups(address trader)
        external
        view
        returns (uint256[] memory groups);

    
    /**
     * @notice used to get  group information
     * @param groupId  group id
     * @return info   info of the group
     */
    function getGroupInfo(uint256 groupId) external view returns (GroupInfo memory info);


    /**
     * @notice used to get  position information
     * @param positionId  position id
     * @return info   info of the position
     */
    function getPositionInfo(uint256 positionId)
        external
        view
        returns (PositionInfo memory info);

    /**
     * @notice returns the total used collateral in positions for the trader
     * @param trader       trader address
     * @return collateral total used collateral in positions
     */
    function getTotalUsedCollateralInPositions(address trader)
        external
        view
        returns (uint256 collateral);


     /**
     * @notice used to get  default group of if the trader 
     * @param trader  trader address
     * @return defaultGroupId  default group id for the trader
     */
    function getDefaultGroupForTrader(address trader) 
        external    
        view
        returns(uint256 defaultGroupId);

    /**
    * @notice to get maintenance margin requirement for position
    * @param positionId position id
    * @return marginRequired margin required for the position
     */
     function getMarginRequirementForPositionLiquidation(uint256 positionId) external view returns(int256 marginRequired);

     
     /**
    * @notice to get maintenance margin requirement for group
    * @param groupId group id
    * @return marginRequired margin required for the group
     */
     function getMarginRequirementForGroupLiquidation(uint256 groupId) 
        external
        view
        returns(int256 marginRequired);

     /**
    * @notice to get maintenance margin requirement for liquidity order
    * @param orderId order id
    * @param baseToken base token address
    * @return marginRequired margin required for the liquidity order
     */
     function getMarginRequirementForLiquidityOrderLiquidation(bytes32 orderId,address baseToken) 
        external
        view
        returns(int256 marginRequired);


    function getTraderTotalLiquidityUnrealisedPnL(address _trader) external view returns(int256 _unrealisedPnL);

     /**
     * @notice used to get unrealised PnL of liquidity position by order id.
     * @param _baseToken base token address
     * @param _orderId  order id 
     * @return _unrealizedPnL unrealized Profit or loss from liquidity position
     */
    function getLiquidityPositionUnrealisedPnL(address _baseToken,bytes32 _orderId) external view returns(int256 _unrealizedPnL);
     /**
     * @notice used to get total value of base token of a particular position.
     * @param positionID position id
     */
     function getBaseTokenValue(uint256 positionID) external view returns (int256);

    /**
     * @notice used to get trader PnL(Unrealised and Realised).
     * @param trader  address of the trader.
     * @param isIsolate true for isolated position and false for grouping
     * @return unrealizedPnL returns unrealized Pnl of either all isolate poistion or grouped positions
     * @return realizedPnL return realized PnL of either all isolate poistion or grouped positions
     */
    function getTraderPnLBy(address trader, bool isIsolate) external view returns(int256 unrealizedPnL, int256 realizedPnL);

     /**
     * @notice used to get trader's group PnL .
     * @param groupId  group id 
     * @return unrealizedPnL unrealized Pnl of the group
     * @return realizedPnl unrealized PnL of the group
     */
    function getGroupPnL(uint256 groupId) external view returns(int256 unrealizedPnL, int256 realizedPnl);
    
     /**
     * @notice used to get unrealised PnL.
     * @param positionID  position id 
     * @return unrealizedPnl unrealized PnL of the position
     */
    function getPositionUnrealisedPnL(uint256 positionID) external view returns(int256 unrealizedPnl);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;
pragma abicoder v2;

interface ISwapManager {
    /// @notice structue of swap / parameters required for swap
    ///@param trader           The address of the trader
    ///@param baseToken        The address of the base token
    ///@param isShort             True for short position , false for long position
    ///@param isExactInput      For specifying exactInput or exactOutput
    ///@param specifiedAmount   Amount specified by user.Depending on isExactInput , this can be input or output
    ///@param isClosingPosition If the position is closing or not
    /// @param positionID       position ID
    ///@param sqrtPriceLimitX96 limit on the sqrt price after swap
    struct SwapParams {
        address trader;
        address baseToken;
        bool isShort;
        bool isExactInput;
        uint256 specifiedAmount;
        bool isClosingPosition;
        uint256 positionID;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice structue of response after swap
    ///@param baseAmount        Base Token Amount
    ///@param quoteAmount       Quote token Amount
    ///@param swappedBasePositionSize   Base token amount  
    ///@param swappedQuotePositionSize  Quote token amount     
    ///@param pnlToBeRealized       profit or loss of the trader
    ///@param sqrtPriceAfterX96     sqrt price after swap
    struct SwapResponseParams {
        uint256 baseAmount;
        uint256 quoteAmount;
        int256  swappedBasePositionSize;
        int256  swappedQuotePositionSize;
        uint256 fee;
        uint256 insuranceFee;
        int24 tick;
        int256  pnlToBeRealized;
        uint256 sqrtPriceAfterX96;
    }

    struct SwapCallbackData {
        address trader;
        address baseToken;
        address uniswapPool;
        uint256 fee;
        uint24 uniswapFee;
    }

    struct InternalSwapResponse {
        int256 baseAmount;
        int256 quoteAmount;
        int256 swappedBaseSize;
        int256 swappedQuoteSize;
        uint256 fee;
        uint256 insuranceFee;
        int24 tick;
    }

    /**
     * @notice The function which performs swapping
     * @dev can only be called from Oddz ClearingHouse contract
     * @param params The parameters of the swap
     * @return swapResponse The result of the swap
     */
    function swap(SwapParams memory params)
        external
        returns (SwapResponseParams memory swapResponse);

    
     /**
    *@notice The function which performs swapping
    * @dev can only be called from Oddz ClearingHouse contract
    * @param params The parameters of the swap
    * @return swappedBaseSize The result of the swap (base token amount)
    * @return swappedQuoteSize quote token amount
    * @return feesAmount fees amount
    * @return insuranceFees insurance manager fees
    */
    function liquidityPositionSwap(SwapParams memory params) external
        returns (
            int256 swappedBaseSize,
            int256 swappedQuoteSize,
            uint256 feesAmount,
            uint256 insuranceFees
        );

    /**
     * @notice The function calculates the Pnl when reducing a position
     * @dev can only be called from Oddz ClearingHouse contract
     * @param positionId The position id
     * @param baseAmount the base amount which is being reduced
     * @param quoteAmount the quote amount which is being reduced
     * @return pnlToBeRealized pnl to be realized
     */
    function getPnLToBeRealized(
        uint256 positionId,
        int256 baseAmount,
        int256 quoteAmount
    ) external view returns (int256 pnlToBeRealized);

    /**
     *@notice used to to get twap mark price
     *@param baseToken base token address
     *@param twapInterval twap interval
     *@return markPrice twap mark price
     */
    function getSqrtMarkTwapX96(address baseToken, uint32 twapInterval)
        external
        view
        returns (uint160 markPrice);

    /** @notice used to get pending funding payment
    *   @param positionId position id
    *   @return fundingPayment funding payment
    */
    function getPositionPendingFundingPayment(uint256 positionId) 
        external 
        view 
        returns (int256 fundingPayment);

    /**@notice used to get pending funding payment
    *  @param orderId liquidity order id
    *  @param baseToken base token address
    *  @return fundingPayment funding payment
    */
    function getLiquidityPositionPendingFundingPayment(bytes32 orderId,address baseToken)
        external 
        view 
        returns(int256 fundingPayment);

    /**
     *@notice settle funding of a position (calculated growth variables , if position> 0 then calculate funding payment)
     *@param positionId position id
     *@param baseToken base token address
     *@return fundingPayment funding payment
     *@return twPremiumX96 time weighted premium
     *@return twPremiumDivBySqrtPriceX96 time weighted premium divided by sqrt price
     */
    function settleFunding(uint256 positionId,address baseToken)
        external
        returns (
            int256 fundingPayment,
            int256 twPremiumX96,
            int256 twPremiumDivBySqrtPriceX96
        );


     /**
     *@notice settle funding of a position (calculates growth , funding payment)
     *@param baseToken base token address
     *@param orderId order id
     *@return fundingPayment funding payment
     *@return twPremiumX96 time weighted premium
     *@return twPremiumDivBySqrtPriceX96 time weighted premium divided by sqrt price
     */
    function settleLiquidityPositionFunding(address baseToken,bytes32 orderId)
        external
      
        returns(int256 fundingPayment, int256 twPremiumX96,int256 twPremiumDivBySqrtPriceX96);

     /**
     *@notice calculates funding payment of the position
     *@param positionId position id
     *@param twPremiumX96 time weighted premium
     *@param twPremiumDivBySqrtPriceX96 time weighted premium divided by sqrt price
     * @param fundingPayment  funding payment amount
     */
    function updateFundingGrowth(uint256 positionId,int256 twPremiumX96,int256 twPremiumDivBySqrtPriceX96)
        external
        returns(int256 fundingPayment);

    

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract OddzOwnable is ContextUpgradeable {

    address public owner;
    address public nominatedOwner;

    // __gap is reserved storage for adding more variables
    uint256[50] private __gap;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    /**
     * @dev Checks the current caller is owner or not.If not throws error
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable:Caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __OddzOwnable_init() internal initializer {
        __Context_init();
        address deployer = _msgSender();
        owner = deployer;
        emit OwnershipTransferred(address(0), deployer);
    }

    /**
     * @dev For renouncing the ownership , After calling this ,ownership will be 
     *  transfered to zero address 
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        nominatedOwner = address(0);
    }

    /**
     * @dev for nominating a new owner.Can only be called by existing owner
     * @param _newOwner New owner address
     */
    function nominateNewOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable: newOwner can not be zero addresss");
    
        require(_newOwner != owner, "Ownable: newOwner can not be same as current owner");
        // same as candidate
        require(_newOwner != nominatedOwner, "Ownable : already nominated");

        nominatedOwner = _newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function AcceptOwnership() external {
    
        require(nominatedOwner != address(0), "Ownable: No one is nominated");
        require(nominatedOwner == _msgSender(), "Ownable: You are not nominated");

        // emitting event first to avoid caching values
        emit OwnershipTransferred(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "../uniswap/FixedPoint96.sol";
import "../uniswap/FullMath.sol";
import "./OddzSafeCast.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";

library OddzMath {
    using OddzSafeCast for int256;
    using SignedSafeMathUpgradeable for int256;
    using SafeMathUpgradeable for uint256;

    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function formatX10_18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, FixedPoint96.Q96, 1 ether);
    }

    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "PerpMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -OddzSafeCast.toInt256(a);
    }

    function neg128(int128 a) internal pure returns (int128) {
        require(a > -2**127, "PerpMath: inversion overflow");
        return -a;
    }

    function neg128(uint128 a) internal pure returns (int128) {
        return -OddzSafeCast.toInt128(a);
    }

    function divBy10_18(int256 value) internal pure returns (int256) {
        // no overflow here
        return value / (1 ether);
    }

    function divBy10_18(uint256 value) internal pure returns (uint256) {
        // no overflow here
        return value / (1 ether);
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, ratio, 1e6);
    }

    /// @param denominator cannot be 0 and is checked in FullMath.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = FullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : OddzSafeCast.toInt256(unsignedResult);

        return result;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

interface IOddzVault {
 


    /**
    * @notice returns settlement token decimals
     */
    function settlementTokenDecimals() external view returns(uint8);

      /**
     * @notice Returns how much margin is available for the isolated position
     * @param trader The Address of the trader
     * @param positionID  position id for which we are checking the collateral
     * @param ratio    ratio (initial margin ratio or maintenance margin ratio)
     */
    function getPositionCollateralByRatio(address trader,uint256 positionID, uint24 ratio) external view returns (int256);

      /**
     * @notice Returns how much margin is available for the group
     * @param trader The Address of the trader
     * @param groupID  group id for which we are checking the collateral
     * @param ratio    ratio (initial margin ratio or maintenance margin ratio)
     */
     function getGroupCollateralByRatio(
        address trader,
        uint256 groupID,
        uint24 ratio
    ) external view returns (int256);


     /**
     * @notice Returns how much margin is available for the liquidity order
     * @param trader The Address of the trader
     * @param baseToken base token address
     * @param orderID liquidity order for which we are checking the collateral
     * @param ratio    ratio (initial margin ratio or maintenance margin ratio)
     */
    function getLiquidityPositionCollateralByRatio(address trader,address baseToken,bytes32 orderID, uint24 ratio) external view returns (int256);

    
     /**
     * @notice updates the main balance of the trader.Called to settle owed Realized PnL.Can only be called by balance manager
     * @param trader The Address of the trader
     * @param amount settlement amount
     */
     function updateCollateralBalance(address trader,int256 amount) external;

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

/**
 * @dev copy from "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol"
 * and rename to avoid naming conflict with uniswap
 */
library OddzSafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128 returnValue) {
        require(((returnValue = uint128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64 returnValue) {
        require(((returnValue = uint64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32 returnValue) {
        require(((returnValue = uint32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16 returnValue) {
        require(((returnValue = uint16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8 returnValue) {
        require(((returnValue = uint8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 returnValue) {
        require(((returnValue = int128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 returnValue) {
        require(((returnValue = int64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 returnValue) {
        require(((returnValue = int32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 returnValue) {
        require(((returnValue = int16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 returnValue) {
        require(((returnValue = int8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }


    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 returnValue) {
        require(((returnValue = int24(value)) == value), "SafeCast: value doesn't fit in an 24 bits");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

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
            require(denominator > 0);
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
        uint256 twos = -denominator & denominator;
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