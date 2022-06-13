//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeableV2/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeableV2/utils/AddressUpgradeable.sol";
import "./interfaces/IOddzVault.sol";
import "./interfaces/IBalanceManager.sol";
import "./interfaces/IOddzClearingHouse.sol";
import "./interfaces/ISwapManager.sol";
import "./interfaces/IOrderManager.sol";
import "./interfaces/IOddzConfig.sol";
import "./utils/oddzPausableV2.sol";
import "./utils/BlockContextV2.sol";
import "./maths/OddzMathV2.sol";

contract OddzClearingHouseExtended is
    ReentrancyGuardUpgradeable,
    OddzPausable,
    BlockContext
{
    using AddressUpgradeable for address;
    using OddzMathV2 for int256;


   

     ///@param sourcePositionId id of the position which we are moving
    /// @param sourceGroupId   id of the group in which sourcePositionId is present
    /// @param destinationPositionId id of the position to which this sourvePositionId is merged
    /// @param destinationGroupId    if of the group of destinationPositionId
    event PositionMoved(
        uint256 sourcePositionId,
        uint256 sourceGroupId,
        uint256 destinationPositionId,
        uint256 destinationGroupId
    );

    /// @param positionId position id
    /// @param groupId     group id
    /// @param quoteSize   position exchanged quote amount
    /// @param liquidator  liquidator address
    event PositionLiquidated(
        uint256 positionId,
        uint256 groupId,
        uint256 quoteSize,
        address liquidator
    );

    event GroupLiquidated(
           uint256 groupId,
        uint256 quoteSize,
        address liquidator
        );

    /// @param trader The address of the trader
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param groupID  group id
    ///@param positionID position id
    /// @param swappedBasePositionSize     base token swapped/recieved(- if transfered , + if recieved)
    /// @param swappedQuotePositionSize quote token swapped/recieved(- if transfered , + if recieved)
    /// @param CHFee fee charged in clearing house.
    /// @param pnlToBeRealized      profit or loss of the trader
    /// @param sqrtPriceAfterX96    sqrt price after swap
    event PositionUpdated(
        address trader,
        address baseToken,
        uint256 groupID,
        uint256 positionID,
        int256 swappedBasePositionSize,
        int256 swappedQuotePositionSize,
        uint256 CHFee,
        int256 pnlToBeRealized,
        uint256 sqrtPriceAfterX96
    );

    /// @notice Emitted when liquidity of a order changed
    /// @param trader The one who provide liquidity
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param quoteToken The address of virtual USD token
    /// @param lowerTickOfOrder The lower tick of the position in which to add liquidity
    /// @param upperTickOfOrder The upper tick of the position in which to add liquidity
    /// @param baseAmount The amount of base token added
    /// @param quoteAmount The amount of quote token added ... (same as the above)
    /// @param orderId      order id of the liquidity position
    /// @param liquidityAmount The amount of liquidity unit added (> 0) / removed (< 0)
    /// @param quoteFee quoteFee the amount of quote token the maker received as fees.
    event LiquidityUpdated(
        address indexed trader,
        address indexed baseToken,
        address indexed quoteToken,
        int24 lowerTickOfOrder,
        int24 upperTickOfOrder,
        uint256 baseAmount,
        uint256 quoteAmount,
        uint128 liquidityAmount,
        uint256 quoteFee,
        bytes32 orderId,
        bool liquidityAdded
    );


     address public oddzVault;
    address public balanceManager;
    address public oddzClearingHouse;
    address public swapManager;
    address public oddzConfig;
    address public orderManager;

    


    // To check deadline before calling add and remove liquidity and before calling open and close position.
    modifier checkExpiry(uint256 deadline) {
        // require deadline should be greater and equal to current timestamp.
        require(
            _blockTimestamp() <= deadline,
            //OddzClearingHouseExtended : Transaction has expired
            "OCHE:TE"
        );
        _;
    }


    function initialize(
        address _oddzVault,
        address _balanceManager,
        address _swapManager,
        address _oddzConfig,
        address _orderManager
    ) public initializer {
        require(
            _oddzVault.isContract(),
            "OddzClearingHouseExtended: vault should be a contract"
        );

        require(
            _balanceManager.isContract(),
            "OddzClearingHouseExtended: balanceManager should be a contract"
        );

        require(
            _swapManager.isContract(),
            "OddzClearingHouseExtended: swapManager should be a contract"
        );

        require(
            _oddzConfig.isContract(),
            "OddzClearingHouseExtended: oddzConfig should be a contract"
        );

        require(
            _orderManager.isContract(),
            "OddzClearingHouseExtended: order Manager should be a contract"
        );

        __ReentrancyGuard_init();
        __OddzPausable_init();

        oddzVault = _oddzVault;
        balanceManager = _balanceManager;
        swapManager=_swapManager;
        oddzConfig=_oddzConfig;
        orderManager=_orderManager;
    }
 
    /**
     * @notice Used to update clearing house contract address
     * @param _clearingHouse Address of the clearing house contract
     */

    function updateClearingHouse(address _clearingHouse) external onlyOwner {
        require(
            _clearingHouse.isContract(),
            "ClearingHouseExtended: clearing house should be a contract"
        );
        oddzClearingHouse = _clearingHouse;
    }


     /**
    *@notice function to use to move isolate or grouped position to a group
    * @param positionId position id to be moved
    * @param groupId the id of the group to which position should be moved
    * @param collateral collateral to be allocated
     */
    function moveToGroup(uint256 positionId ,uint256 groupId,bool isDefaultGroup,uint256 collateral)
        external
        whenNotPaused
        nonReentrant
    {
        address trader = _msgSender();

        IBalanceManager.PositionInfo memory positionInfo=IBalanceManager(balanceManager).getPositionInfo(positionId);

        require(trader==positionInfo.trader,"OddzClearingHouseExtended: Invalid position id");

        

        if(isDefaultGroup){
            // fetched the default group id
            groupId=IBalanceManager(balanceManager).getDefaultGroupForTrader(trader);

            // if no default group id is generated then generate and update
            if(groupId==0){
                groupId=IOddzClearingHouse(oddzClearingHouse).updateGroupID();
                IBalanceManager(balanceManager).updateTraderDefaultGroupID(trader,groupId);
            }
        }

        IBalanceManager.GroupInfo memory groupInfo=IBalanceManager(balanceManager).getGroupInfo(groupId);

        require(trader==groupInfo.trader,"OddzClearingHouseExtended: Invalid group id");

        bool marketPresent;
        uint256 groupPositionId;
        int256 pnlToBeRealized;

        // check if this market position is already present or not
        // if yes then fetch psition id of that position
        for (uint256 i = 0; i < groupInfo.groupPositions.length; i++) {
            if (groupInfo.groupPositions[i].baseToken == positionInfo.baseToken) {
                marketPresent = true;
                groupPositionId = groupInfo.groupPositions[i].positionID;
            }
        }

        IOddzClearingHouse(oddzClearingHouse).settlePositionFunding(positionId,positionInfo.baseToken);
        if(groupPositionId !=0){
            IOddzClearingHouse(oddzClearingHouse).settlePositionFunding(groupPositionId,positionInfo.baseToken);
        }

        if(!marketPresent){
            IBalanceManager(balanceManager).updateTraderPositionInfo(
                positionInfo.trader,
                positionInfo.baseToken,
                positionId,
                0,
                0,
                groupId
            );

            IBalanceManager(balanceManager).updateTraderGroupAndPosition(
                positionId,
                groupPositionId,
                groupId,
                0,
                positionInfo.groupID,
                collateral,
                false
            );

            emit PositionMoved(
                positionId,
                positionInfo.groupID,
                positionId,
                groupId
            );
        }else{

           
            // when merging the position , it will check if the existing position is being reduced if yes then calculates PnL
            if(positionInfo.takerBasePositionSize!=0){
                pnlToBeRealized=ISwapManager(swapManager).getPnLToBeRealized(
                    positionId,
                    positionInfo.takerBasePositionSize,
                    positionInfo.takerQuoteSize
                );
            }

            //if market is present , then use exiting position
            // merge the current position with existing one
            // update the trader position info
            IBalanceManager(balanceManager).updateTraderPositionInfo(
                positionInfo.trader,
                positionInfo.baseToken,
                groupPositionId,
                positionInfo.takerBasePositionSize,
                positionInfo.takerQuoteSize,
                groupId
            );

            // fetch the position info
            IBalanceManager.PositionInfo memory latestPositionInfo = IBalanceManager(
                balanceManager
            ).getPositionInfo(positionId);

            
            IBalanceManager(balanceManager).updateTraderGroupAndPosition(
                positionId,
                groupPositionId,
                groupId,
                latestPositionInfo.owedRealizedPnl,
                positionInfo.groupID,
                collateral,
                true
            );

            emit PositionMoved(
                positionId,
                positionInfo.groupID,
                groupPositionId,
                groupId
            );
            
        }

        if (pnlToBeRealized !=0) {
            IBalanceManager(balanceManager).settleQuoteToOwedRealizedPnl(
                groupPositionId,
                pnlToBeRealized
            );
        }

        // checks the collateral requirement of positions' new group
        _checkGroupCollateralRequirement(positionInfo.trader, groupId);
        // checks the collateral requirement of positions' old group
        _checkGroupCollateralRequirement(positionInfo.trader, positionInfo.groupID);

        

        emit PositionUpdated(
            positionInfo.trader,
            positionInfo.baseToken,
            groupId,
            positionId,
            positionInfo.takerBasePositionSize,
            positionInfo.takerQuoteSize,
            0,
            pnlToBeRealized,
            0
        );

    } 


     /**
    *@notice function to use to move grouped position out of the group to an isolate position
    * @param positionId position id to be moved
    * @param collateral collateral to be allocated
     */
    function moveOutFromGroup(uint256 positionId,uint256 collateral)
        external
        whenNotPaused
        nonReentrant{
            address trader = _msgSender();

             
            // check if this market position is already present or not
            // if yes then fetch psition id of that position
            IBalanceManager.PositionInfo memory positionInfo=IBalanceManager(balanceManager).getPositionInfo(positionId);
            require(positionInfo.groupID>0,"OddzClearingHouseExtended: Position is already a isolate position");
            IBalanceManager.GroupInfo memory groupInfo=IBalanceManager(balanceManager).getGroupInfo(positionInfo.groupID);
            
            require(groupInfo.trader==trader,"OddzClearingHouseExtended: Invalid GroupId");

            IOddzClearingHouse(oddzClearingHouse).settlePositionFunding(positionId,positionInfo.baseToken);

            IBalanceManager(balanceManager).updateTraderPositionInfo(
                positionInfo.trader,
                positionInfo.baseToken,
                positionId,
                0,
                0,
                0
            );

            IBalanceManager(balanceManager).updatePositionsInGroup(positionId,positionInfo.groupID);

            IBalanceManager(balanceManager).updateCollateral(positionId, collateral);

            //checks for the collateral of the isolated position
            _checkCollateralRequirement(positionInfo.trader, positionId);

            // checks the collateral requirement of positions' old group
            _checkGroupCollateralRequirement(positionInfo.trader, positionInfo.groupID);

            emit PositionMoved(
                positionId,
                positionInfo.groupID,
                positionId,
                0
            );

    }

      /**
    * @notice used to liquidate a position
    * @param positionId positin id of the position to be liquidated
    * @param oppositeBoundAmount opposite amount bound for slippage
    * @param deadline transaction expiration
    * @return baseAmount base token amount
    * @return quoteAmount quote token amount
     */ 
    function liquidatePosition(uint256 positionId,uint256 oppositeBoundAmount,uint256 deadline)
        external
        whenNotPaused
        nonReentrant
        checkExpiry(deadline)
        returns(uint256 baseAmount,uint256 quoteAmount)
    {

        address liquidator = _msgSender();
        
        IBalanceManager.PositionInfo memory positionInfo = IBalanceManager(balanceManager)
            .getPositionInfo(positionId);

         // checks if there is any position or not
        require(
            positionInfo.takerBasePositionSize != 0,
            "OddzClearingHouseExtended : No position"
        );

        require(
            positionInfo.groupID==0,
            "OddzClearingHouseExtended : grouped position"
        );

         // if the current position is long then isShort -> true or vice versa
        bool isShort = positionInfo.takerBasePositionSize > 0;

        require(
            IBalanceManager(balanceManager).getPositionCollateralValue(positionId) < 
            IBalanceManager(balanceManager).getMarginRequirementForPositionLiquidation(positionId),
            "OddzClearingHouseExtended : enough collateral"
        );

        IOddzClearingHouse(oddzClearingHouse).settlePositionFunding(positionId,positionInfo.baseToken);

        IOddzClearingHouse.ClosePositionHandlerParams
            memory closePositionHandlerParams =IOddzClearingHouse.ClosePositionHandlerParams({
                trader: positionInfo.trader,
                baseToken: positionInfo.baseToken,
                isShort: isShort,
                specifiedAmount: positionInfo.takerBasePositionSize.abs(),
                isExactInput: isShort,
                positionID: positionId,
                sqrtPriceLimitX96: 0
            });
        
        // calls position handler function internally to get base amount and quote amount after closing position.
        IOddzClearingHouse.SwapResponseParams memory _response = IOddzClearingHouse(oddzClearingHouse).closePositionHandler(
            closePositionHandlerParams
        );

        _checkSlippage(isShort, isShort, _response.baseAmount, _response.quoteAmount, oppositeBoundAmount);

        IBalanceManager(balanceManager).updateLiquidationFees(liquidator,positionInfo.trader, _response.swappedQuotePositionSize);

        emit PositionLiquidated(
            positionId,
            0,
            _response.swappedQuotePositionSize.abs(),
            liquidator
        );

        return (_response.baseAmount,_response.quoteAmount);
    }

     /**
    * @notice used to liquidate a group
    * @param groupId group id of the group to be liquidated
    * @param deadline transaction expiration
     */ 
    function liquidateGroup(uint256 groupId,uint256 deadline)
        external
        whenNotPaused
        nonReentrant
        checkExpiry(deadline)
    {
        address liquidator = _msgSender();

        require(
            IBalanceManager(balanceManager).getGroupCollateralValue(groupId) < 
            IBalanceManager(balanceManager).getMarginRequirementForGroupLiquidation(groupId),
            "OddzClearingHouseExtended : enough collateral"
        );

        IBalanceManager.GroupInfo memory groupInfo=IBalanceManager(balanceManager).getGroupInfo(groupId);

        IBalanceManager.PositionInfo memory positionInfo;
        uint256 positionId;
        int256 totalSwappedQuoteSize;

        require(groupInfo.groupPositions.length!=0,"OddzClearingHouseExtended : No positions");

        for(uint8 i=0;i<groupInfo.groupPositions.length;i++){
            positionId=groupInfo.groupPositions[i].positionID;
            positionInfo=IBalanceManager(balanceManager).getPositionInfo(positionId);

            IOddzClearingHouse(oddzClearingHouse).settlePositionFunding(positionId,positionInfo.baseToken);

            // if the current position is long then isShort -> true or vice versa
            bool isShort = positionInfo.takerBasePositionSize > 0;
           IOddzClearingHouse.ClosePositionHandlerParams memory closePositionHandlerParams =IOddzClearingHouse.ClosePositionHandlerParams({
                trader: positionInfo.trader,
                baseToken: positionInfo.baseToken,
                isShort: isShort,
                specifiedAmount: positionInfo.takerBasePositionSize.abs(),
                isExactInput: isShort,
                positionID: groupInfo.groupPositions[i].positionID,
                sqrtPriceLimitX96: 0
            });
        
            // calls position handler function internally to get base amount and quote amount after closing position.
            IOddzClearingHouse.SwapResponseParams memory _response = IOddzClearingHouse(oddzClearingHouse).closePositionHandler(
                closePositionHandlerParams
            );

            totalSwappedQuoteSize= totalSwappedQuoteSize+_response.swappedQuotePositionSize;

            emit PositionLiquidated(
                groupInfo.groupPositions[i].positionID,
                groupId,
                _response.swappedQuotePositionSize.abs(),
                liquidator
            );
        }
        emit GroupLiquidated(
            groupId,
            totalSwappedQuoteSize.abs(),
            liquidator
        );

        IBalanceManager(balanceManager).updateLiquidationFees(liquidator,groupInfo.trader, totalSwappedQuoteSize);
    }


     /**
    * @notice used to liquidate a impermanent position
    * @param trader  trader address
    * @param baseToken base token address
    * @param orderId  order Id
    * @param minimumBaseAmount minimum base amount 
    * @param minimumQuoteAmount minimum quote amount
    * @param deadline transaction expiration
     */
    function liquidateLiquidityOrder(address trader,address baseToken,bytes32 orderId , uint256 minimumBaseAmount,uint256 minimumQuoteAmount,uint256 deadline)
        external
        whenNotPaused
        nonReentrant
        checkExpiry(deadline)
    {
        require(
               IBalanceManager(balanceManager).getLiquidityOrderCollateralValue(orderId,baseToken) 
               < IBalanceManager(balanceManager).getMarginRequirementForLiquidityOrderLiquidation(orderId,baseToken),
            "OddzClearingHouseExtended: enough collateral"
        );

        IOddzClearingHouse.FundingGrowth memory fundingGrowth;
        fundingGrowth=IOddzClearingHouse(oddzClearingHouse).settleLiquidityPositionFunding(baseToken,orderId);

        IOrderManager.OrderInfo memory orderInfo=IOrderManager(orderManager).getCurrentOrderMap(orderId);

        require(orderInfo.trader == trader,"OddzClearingHouseExtended:Not valid trader address");

        IOrderManager.RemoveLiquidityResponse memory response = IOrderManager(
            orderManager
        ).removeLiquidity(
                IOrderManager.RemoveLiquidityParams({
                    trader: trader,
                    baseToken: baseToken,
                    lowerTickOfOrder: orderInfo.lowerTick,
                    upperTickOfOrder: orderInfo.upperTick,
                    liquidityAmount: orderInfo.liquidity
                })
            );
        IOddzClearingHouse.RemoveLiquidityParams memory params=IOddzClearingHouse.RemoveLiquidityParams({
            baseToken:baseToken,
            lowerTickOfOrder:orderInfo.upperTick,
            upperTickOfOrder:orderInfo.upperTick,
            liquidityAmount:orderInfo.liquidity,
            isClose:true,
            isIsolate:false,
            isDefaultGroup:false,
            groupID:0,
            positionID:0,
            collateralForPosition:0,
            minimumBaseAmount:0,
            minimumQuoteAmount:0,
            deadline:0
        });

        IOddzClearingHouse(oddzClearingHouse).settleLiquidityGeneratedPosition(trader, params, response,fundingGrowth);
        // settles impermanent position generated from liquidity position


        //Check for slippage
        require(
            response.baseAmount >=minimumBaseAmount &&
                response.quoteAmount >= minimumQuoteAmount,
            "OddzClearingHouseExtended: High Slippage"
        );

        //Emits an event after removing liqiudity
        emit LiquidityUpdated(
            trader,
            params.baseToken,
            params.baseToken,// needs tp change that to quote
            params.lowerTickOfOrder,
            params.upperTickOfOrder,
            response.baseAmount,
            response.quoteAmount,
            params.liquidityAmount,
            response.feeAmount,
            response.orderId,
            false
        );
    }


    /**
     * @notice Checks if there is enough collateral or not for a isolated position
     * @param _trader The Address of the trader
     * @param _positionID position id for which we are checking the collateral
     */
    function _checkCollateralRequirement(address _trader, uint256 _positionID)
        internal
        view
    {
        require(
            IOddzVault(oddzVault).getPositionCollateralByRatio(
                _trader,
                _positionID,
                IOddzConfig(oddzConfig).initialMarginRatio()
            ) >= 0,
            "OddzClearingHouseExtended : Not enough collateral"
        );
    }

    /**
     * @notice Checks if there is enough collateral or not for a group
     * @param _trader The Address of the trader
     * @param _groupID group id for which we are checking the collateral
     */
    function _checkGroupCollateralRequirement(address _trader, uint256 _groupID)
        internal
        view
    {
        require(
            IOddzVault(oddzVault).getGroupCollateralByRatio(
                _trader,
                _groupID,
                IOddzConfig(oddzConfig).initialMarginRatio()
            ) >= 0,
            "OddzClearingHouseExtended : Not enough collateral"
        );
    }

     function _checkSlippage(
        bool _isShort,
        bool _isExactInput,
        uint256 _baseAmount,
        uint256 _quoteAmount,
        uint256 _oppositeBoundAmount
    ) internal pure{

        //Slippage checks
        if (_oppositeBoundAmount != 0) {
            if (_isShort) {
                if (_isExactInput) {
                    require(
                        _quoteAmount >= _oppositeBoundAmount,
                        //received less on short
                        "OCHE :RLOS"

                    );
                } else {
                    require(
                        _baseAmount <= _oppositeBoundAmount,
                        //requested more on short
                        "OCHE :RMOS"
                    );
                }
            } else {
                if (_isExactInput) {
                    require(
                        _baseAmount >= _oppositeBoundAmount,
                        //received less on long
                        "OCHE : RLOL"

                    );
                } else {
                    require(
                        _quoteAmount <= _oppositeBoundAmount,
                        //requested more on long
                        "OCHE :RMOL"

                    );
                }
            }
        }
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./IOrderManager.sol";

interface IOddzClearingHouse{


    /// @param baseToken               Base token address
    /// @param lowerTickOfOrder        Lower tick of liquidity range
    /// @param upperTickOfOrder        Upper tick of liquidity range
    /// @param liquidityAmount         Amount of liquidity you want to remove
    /// @param isClose                True if wants to close the position
    /// @param isIsolate               position is isolate or cross margin
    /// @param isDefaultGroup          true if wants to use default group
    /// @param groupID                 if isIsolate is false then if groupID => 0 then create new group else use groupID
    /// @param positionID              position id id using existing position otherwise create new
    /// @param collateralForPosition   collateral should be allocated to new position
    /// @param minimumBaseAmount       The minimum amount of base token you'd like to get back
    /// @param minimumQuoteAmount      The minimum amount of quote token you'd like to get back
    /// @param deadline                Time after which the transaction can no longer be executed
    struct RemoveLiquidityParams {
        address baseToken;
        int24 lowerTickOfOrder;
        int24 upperTickOfOrder;
        uint128 liquidityAmount;
        bool isClose;
        bool isIsolate;
        bool isDefaultGroup;
        uint256 groupID;
        uint256 positionID;
        uint256 collateralForPosition;
        uint256 minimumBaseAmount;
        uint256 minimumQuoteAmount;
        uint256 deadline;
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

    ///@param trader                   Address of the trader
    /// @param baseToken               Base token address
    /// @param isShort                 True for opening short position,false for long
    /// @param specifiedAmount         Amount entered by trader
    /// @param isExactInput            True for exact input ,false for exact output
    /// @param positionID             position ID
    /// @param sqrtPriceLimitX96       Price limit same as uniswap V3
    struct ClosePositionHandlerParams {
        address trader;
        address baseToken;
        bool isShort;
        uint256 specifiedAmount;
        bool isExactInput;
        uint256 positionID;
        uint160 sqrtPriceLimitX96;
    }

     struct FundingGrowth {
        int256 twPremiumX96;
        int256 twPremiumDivBySqrtPriceX96;
    }

    function updateGroupID() external returns(uint256 _groupId);

    function settlePositionFunding(uint256 positionId, address baseToken) external ;

    function settleLiquidityPositionFunding(address baseToken,bytes32 orderId) external returns(FundingGrowth memory fundingGrowth) ;

    function closePositionHandler(ClosePositionHandlerParams calldata params)
        external 
        returns(SwapResponseParams memory _response );
    
    function settleLiquidityGeneratedPosition(
        address trader,
        RemoveLiquidityParams memory params,
        IOrderManager.RemoveLiquidityResponse memory response ,
        FundingGrowth memory fundingGrowth
        )
        external;
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
pragma solidity ^0.8.0;

import  "@openzeppelin/contracts-upgradeableV2/security/PausableUpgradeable.sol";
import  "./oddzOwnableV2.sol";

abstract contract OddzPausable is OddzOwnable, PausableUpgradeable {
    // __gap is reserved storage
    uint256[50] private __gap;


    function __OddzPausable_init() internal initializer {
        __OddzOwnable_init();
        __Pausable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _msgSender() internal view virtual override returns (address ) {
        return (super._msgSender());
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract BlockContext {
    function _blockTimestamp() internal view virtual returns (uint256) {
        // Reply from Arbitrum
        // block.timestamp returns timestamp at the time at which the sequencer receives the tx.
        // It may not actually correspond to a particular L1 block
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./OddzSafeCast.sol";

library OddzMathV2 {
    using OddzSafeCast for int256;

   

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }
    
    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "PerpMath: inversion overflow");
        return -a;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeableV2/utils/ContextUpgradeable.sol";

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