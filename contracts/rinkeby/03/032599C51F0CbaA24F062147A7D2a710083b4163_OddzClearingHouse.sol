//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeableV2/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeableV2/utils/AddressUpgradeable.sol";
import "./uniswap/IUniswapV3MintCallback.sol";
import "./uniswap/IUniswapV3SwapCallback.sol";
import "./uniswap/IUniswapV3Pool.sol";
import "./interfaces/IOddzConfig.sol";
import "./interfaces/IOddzVault.sol";
import "./interfaces/IBalanceManager.sol";
import "./interfaces/IERC20MetadataV2.sol";
import "./interfaces/IOrderManager.sol";
import "./interfaces/ISwapManager.sol";
import "./interfaces/IVolumeManager.sol";
import "./utils/oddzPausableV2.sol";
import "./utils/BlockContextV2.sol";
import "./maths/OddzSafeCast.sol";
import "./maths/OddzMathV2.sol";

contract OddzClearingHouse is
    ReentrancyGuardUpgradeable,
    OddzPausable,
    BlockContext,
    IUniswapV3MintCallback,
    IUniswapV3SwapCallback
{
    using AddressUpgradeable for address;
    using OddzSafeCast for uint256;
    using OddzSafeCast for uint128;
    using OddzSafeCast for int256;
    using OddzMathV2 for int256;

    /// @param baseToken                Base token address
    /// @param baseAmount               Base token amount
    /// @param quoteAmount              Quote token amount
    /// @param lowerTickOfOrder         Lower tick of liquidity range
    /// @param upperTickOfOrder         Upper tick of liquidity range
    /// @param minimumBaseAmountnBase   The minimum amount of base token you'd like to provide
    /// @param minimumQuoteAmount       The minimum amount of quote token you'd like to provide
    /// @param collateralForOrder       Collateral used for this position
    /// @param deadline                 Time after which the transaction can no longer be executed
    struct AddLiquidityParams {
        address baseToken;
        uint256 baseAmount;
        uint256 quoteAmount;
        int24 lowerTickOfOrder;
        int24 upperTickOfOrder;
        uint256 minimumBaseAmount;
        uint256 minimumQuoteAmount;
        uint256 collateralForOrder;
        uint256 deadline;
    }

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

    /// @param baseToken               Base token address
    /// @param isIsolate               position is isolate or cross margin
    /// @param isShort                 True for opening short position,false for long
    /// @param specifiedAmount         Amount entered by trader
    /// @param isExactInput            True for exact input ,false for exact output
    /// @param oppositeBoundAmount     Depending on long/short and isExactInput/Output , limit on tokens to pay/recieve
    /// @param isDefaultGroup          true if wants to use default group
    /// @param groupId                 Group Id , 0 in case user don;t want to use group
    /// @param isNewGroup              true if wanted to create a new group
    /// @param collateralForPosition   Collateral that will be used for position
    /// @param sqrtPriceLimitX96       Price limit same as uniswap V3
    /// @param deadline                Time after which the transaction can no longer be executed
    struct PositionOpeningParams {
        address baseToken;
        bool isIsolate;
        bool isShort;
        uint256 specifiedAmount;
        bool isExactInput;
        uint256 oppositeBoundAmount;
        bool isDefaultGroup;
        uint256 groupId;
        bool isNewGroup;
        uint256 collateralForPosition;
        uint160 sqrtPriceLimitX96;
        uint256 deadline;
    }

    /// @param positionID              position id which user want to close
    /// @param oppositeBoundAmount     Depending on long/short and isExactInput/Output , limit on tokens to pay/recieve
    /// @param sqrtPriceLimitX96       Price limit same as uniswap V3
    /// @param deadline                Time after which the transaction can no longer be executed
    struct PositionClosingParams {
        uint256 positionID;
        uint256 oppositeBoundAmount;
        uint160 sqrtPriceLimitX96;
        uint256 deadline;
    }

    ///@param trader                   Address of the trader
    /// @param baseToken               Base token address
    /// @param isIsolate               position is isolate or grouped
    /// @param isShort                 True for opening short position,false for long
    /// @param specifiedAmount         Amount entered by trader
    /// @param isExactInput            True for exact input ,false for exact output
    /// @param isDefaultGroup          true if wants to use default group
    /// @param groupId                 Group id 
    /// @param isNewgroup              true if want to create new group
    /// @param collateralForPosition   Collateral that will be used for position
    /// @param sqrtPriceLimitX96       Price limit same as uniswap V3
    struct PositionHandlerParams {
        address trader;
        address baseToken;
        bool isIsolate;
        bool isShort;
        uint256 specifiedAmount;
        bool isExactInput;
        bool isDefaultGroup;
        uint256 groupId;
        bool isNewGroup;
        uint256 collateralForPosition;
        uint160 sqrtPriceLimitX96;
    }

    ///@param trader                   Address of the trader
    /// @param baseToken               Base token address
    /// @param isIsolate               position is isolate or grouped
     /// @param isDefaultGroup          true if wants to use default group
    /// @param groupId                 Group Id , 0 in case user don;t want to use group
    /// @param isNewGroup              true if wanted to create a new group
     /// @param collateralForPosition   Collateral that will be used for position
    struct InternalPositionHandlerParams {
        address trader;
        address baseToken;
        bool isIsolate;
         bool isDefaultGroup;
        uint256 groupId;
        bool isNewGroup;
        uint256 collateralForPosition;
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

    //Events

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


    /// @param positionID The position id of trader
    /// @param fundingPayment The fundingPayment of trader's position.
    event FundingPaymentSettled(
        uint256 positionID,
        int256 fundingPayment
    );

    /// @param orderID The order id of 
    /// @param fundingPayment The fundingPayment of liquidity position.
    event LiquidityFundingPaymentSettled(
        bytes32 orderID,
        int256 fundingPayment
    );



    //VARIABLES
    //

    struct FundingGrowth {
        int256 twPremiumX96;
        int256 twPremiumDivBySqrtPriceX96;
    }


    address public quoteToken;

    address public oddzConfig;
    address public oddzVault;
    address public balanceManager;
    address public orderManager;
    address public swapManager;
    address public volumeManager;
    address public clearingHouseExtended;

    uint256 public positionIDGenerator;
    uint256 public groupIDGenerator;

    uint256 internal constant _DUST = 10 wei;

    //MODIFERS
    //
    // To check deadline before calling add and remove liquidity and before calling open and close position.
    modifier checkExpiry(uint256 deadline) {
        // require deadline should be greater and equal to current timestamp.
        require(
            _blockTimestamp() <= deadline,
            //OddzClearingHouse : Transaction has expired
            "OCH:TE"
        );
        _;
    }

     modifier onlyClearingHouseExtended() {
        // require deadline should be greater and equal to current timestamp.
        require(
            _msgSender() <= clearingHouseExtended,
            //Not authorized
            "OCH:NA"
        );
        _;
    }

    /**
     * @dev initialise primary addresses while or after deployement
     */
    function initialize(
        address _oddzConfig,
        address _oddzVault,
        address _quoteToken,
        address _balanceManager,
        address _orderManager,
        address _swapManager,
        address _volumeManager,
        address _clearingHouseExtended
    ) public initializer {
        require(
            _oddzVault.isContract(),
            //vault not a contract
            "OCH:VNC"
        );
        require(
            _oddzConfig.isContract(),
            //config not a contract
            "OCH:CCC"
        );
        require(
            _balanceManager.isContract(),
            //balanceManager not a contract
            "OCH:BNC"
        );
        require(
            _quoteToken.isContract(),
            //quote token not a contract
            "OCH:QNC"
        );
        require(
            _orderManager.isContract(),
            //order manager not a contract
            "OCH:ONC "
        );
        require(
            _swapManager.isContract(),
           //swapManager not a contract
            "OCH :SNC"
        );
        require(
            _volumeManager.isContract(),
            "OddzClearinghouse : volume manager should be a contract"
        );
        require(
            IERC20Metadata(_quoteToken).decimals() == 18,
            //Not valid decimals
            "OCH:NVD"
        );

        __ReentrancyGuard_init();
        __OddzPausable_init();

        // assign to addresses
        oddzConfig = _oddzConfig;
        oddzVault = _oddzVault;
        quoteToken = _quoteToken;
        balanceManager = _balanceManager;
        orderManager = _orderManager;
        swapManager = _swapManager;
        volumeManager = _volumeManager;
        clearingHouseExtended=_clearingHouseExtended;
    }

    /**
     * @notice User calls this function to add liquidity in the uniswap pool
     * @dev parameters are defined above in the structure
     * @param params holds all the parameters required for adding liquidity 
     * @return response response has base amount, quote amout,liquidity amount and order id
     */
    function addLiquidity(AddLiquidityParams calldata params)
        external
        whenNotPaused
        nonReentrant
        checkExpiry(params.deadline)
        returns (
            IOrderManager.AddLiquidityResponse memory response
        )
    {
        address trader = _msgSender();

        bytes32 orderId=IOrderManager(orderManager).calcOrderID(trader,params.baseToken,params.lowerTickOfOrder,params.upperTickOfOrder);

        FundingGrowth memory fundingGrowth;
        fundingGrowth =_settleLiquidityPositionFunding(params.baseToken,orderId);

        //Calls order manager that then handles adding liqudity into the pools
        response = IOrderManager(orderManager).addLiquidity(
            IOrderManager.AddLiquidityParams({
                trader: trader,
                baseToken: params.baseToken,
                baseAmount: params.baseAmount,
                quoteAmount: params.quoteAmount,
                lowerTickOfOrder: params.lowerTickOfOrder,
                upperTickOfOrder: params.upperTickOfOrder,
                collateralForOrder: params.collateralForOrder,
                twPremiumX96 : fundingGrowth.twPremiumX96,
                twPremiumDivBySqrtPriceX96 : fundingGrowth.twPremiumDivBySqrtPriceX96
            })
        );

        //Checks for slippage
        require(
            response.baseAmount >= params.minimumBaseAmount &&
                response.quoteAmount >= params.minimumQuoteAmount,
                //High slippage
            "OCH:HS"
        );

        // check the available collateral here.
        _checkLiquidityCollateralRequirement(trader, params.baseToken, response.orderId);

        //Emit an event after adding liquidity
        emit LiquidityUpdated(
            trader,
            params.baseToken,
            quoteToken,
            params.lowerTickOfOrder,
            params.upperTickOfOrder,
            response.baseAmount,
            response.quoteAmount,
            response.liquidityAmount,
            response.feeAmount,
            response.orderId,
            true
        );
    }

    /**
     * @notice User calls this function to remove thier liquidity from the uniswap pool
     * @dev Takes all the remove liquidity parameters that are defined above
     * @param params holds all the parameters required for removing liquidity
     * @return response holds base amount, quote amount,taker base amount,taker quote amount and order id
     */
    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        whenNotPaused
        nonReentrant
        checkExpiry(params.deadline)
        returns (IOrderManager.RemoveLiquidityResponse memory response )
    {
        address trader = _msgSender();

        bytes32 orderId=IOrderManager(orderManager).calcOrderID(trader,params.baseToken,params.lowerTickOfOrder,params.upperTickOfOrder);

        FundingGrowth memory fundingGrowth;
        fundingGrowth =_settleLiquidityPositionFunding(params.baseToken,orderId);

        //Calles order manager remove liquidity that then handles remove liquidity from uniswap pools
        response = IOrderManager(
            orderManager
        ).removeLiquidity(
                IOrderManager.RemoveLiquidityParams({
                    trader: trader,
                    baseToken: params.baseToken,
                    lowerTickOfOrder: params.lowerTickOfOrder,
                    upperTickOfOrder: params.upperTickOfOrder,
                    liquidityAmount: params.liquidityAmount
                })
            );

        // settles impermanent position generated from liquidity position
        _settleLiquidityGeneratedPosition(trader, params, response,fundingGrowth);

        //Check for slippage
        require(
            response.baseAmount >= params.minimumBaseAmount &&
                response.quoteAmount >= params.minimumQuoteAmount,
            //OCH:High slippage
            "OCH:HS"
        );

        //updated participating markets for the trader
        //_updateParticipatingMarkets(trader, params.baseToken, false);

        //Emits an event after removing liqiudity
        emit LiquidityUpdated(
            trader,
            params.baseToken,
            quoteToken,
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
     * @notice trader calls this function to open position
     * @dev This function internally calls to _positionHandler
     * @param params holds all the parameters required for opening a position
     * returns baseAmount, quoteAmount.
     */
    function openPosition(PositionOpeningParams calldata params)
        external
        whenNotPaused
        nonReentrant
        checkExpiry(params.deadline)
        returns (uint256 baseAmount, uint256 quoteAmount)
    {
        address trader = _msgSender();
        if (params.isIsolate || params.isNewGroup || params.isDefaultGroup) {
            require(
                params.groupId == 0,
                //OddzClearingHouse : For isolated margin and new group, put group id as 0
                //Invalid group
                "OCH:IG"
            );
        } else {
            require(
                params.groupId > 0,
                //OddzClearingHouse : use valid group id
                //Invalid group
                "OddzClearingHouse : use valid group id"
            );
        }
        FundingGrowth memory fundingGrowth;
        fundingGrowth =_settlePositionFunding(0,params.baseToken);

        // update the trader volume and swap fees accordingly.
        _updateTraderVolume(trader, params.specifiedAmount);

        PositionHandlerParams
            memory positionHandlerParams = PositionHandlerParams({
                trader: trader,
                baseToken: params.baseToken,
                isIsolate: params.isIsolate,
                isShort: params.isShort,
                specifiedAmount: params.specifiedAmount,
                isExactInput: params.isExactInput,
                isDefaultGroup :params.isDefaultGroup,
                groupId: params.groupId,
                isNewGroup: params.isNewGroup,
                collateralForPosition: params.collateralForPosition, // if position is grouped then in opening position whatever collateral
                                                                      // is given will be added to the group collateral
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            });

        // calls position handler function internally to get base amount and quote amount.
        (baseAmount, quoteAmount) = _positionHandler(positionHandlerParams,fundingGrowth);

        _checkSlippage(params.isShort,params.isExactInput,baseAmount,quoteAmount,params.oppositeBoundAmount);
    }

    /**
     * @notice trader calls this function to close position
     * @dev This function internally calls to _closePositionHandler
     * @param params holds all the parameters required for closing a position
     * returns baseAmount, quoteAmount after closing position.
     */
    function closePosition(PositionClosingParams calldata params)
        external
        whenNotPaused
        nonReentrant
        checkExpiry(params.deadline)
        returns (uint256 baseAmount, uint256 quoteAmount)
    {
        address trader = _msgSender();

        IBalanceManager.PositionInfo memory info = IBalanceManager(balanceManager)
            .getPositionInfo(params.positionID);

        //OddzClearingHouse:Invalid position id for the trader
        //Invalid position
        require(info.trader==trader, "OCH:IP");
        int256 takerBasePositionSize = IBalanceManager(balanceManager)
            .getTakerBasePositionSize(params.positionID);

        // checks if there is any position or not
        require(
            takerBasePositionSize != 0,
            //OddzClearingHouse : You don't have any position
            //NO position
            "OCH :NP"
        );

        _settlePositionFunding(params.positionID,info.baseToken);

        // if the current position is long then isShort -> true or vice versa
        bool isShort = takerBasePositionSize > 0;
        ClosePositionHandlerParams
            memory closePositionHandlerParams = ClosePositionHandlerParams({
                trader: trader,
                baseToken: info.baseToken,
                isShort: isShort,
                specifiedAmount: takerBasePositionSize.abs(),
                isExactInput: isShort,
                positionID: params.positionID,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            });

        // calls position handler function internally to get base amount and quote amount after closing position.
       ISwapManager.SwapResponseParams memory _response = _closePositionHandler(
            closePositionHandlerParams
        );


        _checkSlippage(isShort,isShort, _response.baseAmount, _response.quoteAmount,params.oppositeBoundAmount);

        return (_response.baseAmount,_response.quoteAmount);
    }
    
    function updateGroupID() external onlyClearingHouseExtended returns(uint256 _groupId) {
       groupIDGenerator= groupIDGenerator+1;
       return groupIDGenerator;
    }


    function settlePositionFunding(uint256 positionId, address baseToken) external onlyClearingHouseExtended{
        _settlePositionFunding(positionId, baseToken);
    }
 
    function settleLiquidityPositionFunding(address baseToken,bytes32 orderId) 
        external
        onlyClearingHouseExtended
        returns(FundingGrowth memory fundingGrowth){
        return _settleLiquidityPositionFunding(baseToken, orderId);
    }


    function closePositionHandler(ClosePositionHandlerParams calldata params)
        external 
        onlyClearingHouseExtended
        returns(ISwapManager.SwapResponseParams memory _response ){
        return _closePositionHandler(params);
    }


    function settleLiquidityGeneratedPosition(
        address trader,
        RemoveLiquidityParams memory params,
        IOrderManager.RemoveLiquidityResponse memory response ,
        FundingGrowth memory fundingGrowth
        )
        external
        onlyClearingHouseExtended
    {
        _settleLiquidityGeneratedPosition(trader,params,response,fundingGrowth);
    }

    /// @inheritdoc IUniswapV3MintCallback
    /// @dev namings here follow Uniswap's convention
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        require(
            msg.sender == orderManager,
            //OddzClearingHouse : Caller should be order manager
            //Caller Not Order manager
            "OCH :COM"
        );

        IOrderManager.MintCallbackData memory callbackData = abi.decode(
            data,
            (IOrderManager.MintCallbackData)
        );

        if (amount0Owed > 0) {
            address token = IUniswapV3Pool(callbackData.pool).token0();
            require(
                IERC20Metadata(token).transfer(callbackData.pool, amount0Owed),
                //OddzClearingHouse : Transfer Failed
                "OCH : TF"
            );
        }
        if (amount1Owed > 0) {
            address token = IUniswapV3Pool(callbackData.pool).token1();
            require(
                IERC20Metadata(token).transfer(callbackData.pool, amount1Owed),
                //OddzClearingHouse : Transfer Failed
                "OCH : TF"
            );
        }
    }

    /// @inheritdoc IUniswapV3SwapCallback
    /// @dev namings here follow Uniswap's convention
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        require(
            msg.sender == swapManager,
            //OddzClearingHouse : Caller should be swap manager
            //OCH: caller not swap manager
            "OCH :CNS"
        );

        require(
            (amount0Delta > 0 && amount1Delta < 0) ||
                (amount0Delta < 0 && amount1Delta > 0),
            //OddzClearingHouse : forbidden 0 swap
            "OCH:ZS"
        );

        ISwapManager.SwapCallbackData memory callbackData = abi.decode(
            data,
            (ISwapManager.SwapCallbackData)
        );
        IUniswapV3Pool uniswapV3Pool = IUniswapV3Pool(callbackData.uniswapPool);

        // amount0Delta & amount1Delta are guaranteed to be positive when being the amount to be paid
        (address token, uint256 amountToPay) = amount0Delta > 0
            ? (uniswapV3Pool.token0(), uint256(amount0Delta))
            : (uniswapV3Pool.token1(), uint256(amount1Delta));

        require(
            IERC20Metadata(token).transfer(
                address(callbackData.uniswapPool),
                amountToPay
            ),
            //OddzClearingHouse: transfer failed
            "OCH:TF"
        );
    }

    
    /**
     * @notice handles position creation based on selected parameters isolated or cross margin
     * @dev This function internally calls to isolate and group position handler
     * @param _params holds all the parameters required in position handler structure
     * returns baseAmount, quoteAmount.
     */
    function _positionHandler(PositionHandlerParams memory _params,FundingGrowth memory fundingGrowth)
        internal
        returns (uint256 _baseAmount, uint256 _quoteAmount)
    {
         //setting up the params for the swap function in swapManager
        ISwapManager.SwapParams memory _swapParams = ISwapManager.SwapParams({
            trader: _params.trader,
            baseToken: _params.baseToken,
            isShort: _params.isShort,
            isExactInput: _params.isExactInput,
            specifiedAmount: _params.specifiedAmount,
            isClosingPosition: false,
            positionID: 0,
            sqrtPriceLimitX96: _params.sqrtPriceLimitX96
        });
        // swaps the token
        ISwapManager.SwapResponseParams memory _response = ISwapManager(
            swapManager
        ).swap(_swapParams);

        // insurance fees always have to be updated to insurance contract.
        IBalanceManager(balanceManager).updateInsuranceManagerFees(_response.insuranceFee.toInt256());

        InternalPositionHandlerParams
            memory internalParams = InternalPositionHandlerParams({
                trader: _params.trader,
                baseToken: _params.baseToken,
                isIsolate: _params.isIsolate,
                isDefaultGroup:_params.isDefaultGroup,
                groupId: _params.groupId,
                isNewGroup: _params.isNewGroup,
                collateralForPosition: _params.collateralForPosition
            });
        if (_params.isIsolate) {
            // to handle isolate position
            _handleIsolatePositions(internalParams, _response,fundingGrowth);
        } else {
            // to handle positions inside a group
            _handleGroupPositions(internalParams, _response,fundingGrowth);
        }

        return (_response.baseAmount, _response.quoteAmount);
    }

     /**
     * @notice handles position closing based on selected parameters isolated or cross margin
     * @dev This function closed the position and updates the variables accordingly
     * @param _params holds all the parameters required in close position handler structure
     * returns baseAmount, quoteAmount.
     */
    function _closePositionHandler(ClosePositionHandlerParams memory _params)
        internal
        returns (ISwapManager.SwapResponseParams memory _response)
    {

        //setting up the params for the swap function in swapManager
        ISwapManager.SwapParams memory _swapParams = ISwapManager.SwapParams({
            trader: _params.trader,
            baseToken: _params.baseToken,
            isShort: _params.isShort,
            isExactInput: _params.isExactInput,
            specifiedAmount: _params.specifiedAmount,
            isClosingPosition: true,
            positionID: _params.positionID,
            sqrtPriceLimitX96: _params.sqrtPriceLimitX96
        });

        //swaps the tokens
        _response = ISwapManager(
            swapManager
        ).swap(_swapParams);

        // insurance fees always have to be updated to insurance contract.
        IBalanceManager(balanceManager).updateInsuranceManagerFees(_response.insuranceFee.toInt256());

        //Fetch the position info for the group information
        IBalanceManager.PositionInfo memory info = IBalanceManager(
            balanceManager
        ).getPositionInfo(_params.positionID);

        // updates the traders position info
        IBalanceManager(balanceManager).updateTraderPositionInfo(
            _params.trader,
            _params.baseToken,
            _params.positionID,
            _response.swappedBasePositionSize,
            _response.swappedQuotePositionSize-(_response.fee.toInt256()), // CH fee charged in quote ammount, 
            info.groupID
        );

        // settle PnL is any
        if (_response.pnlToBeRealized != 0) {
            IBalanceManager(balanceManager).settleQuoteToOwedRealizedPnl(
                _params.positionID,
                _response.pnlToBeRealized
            );
        }

        // is position is grouped then update group and positions otherwise only updates positions
        // accordingly emit events
        if (info.groupID>0) {
            IBalanceManager(balanceManager).updateTraderGroups(
                _params.trader,
                _params.baseToken,
                _params.positionID,
                info.groupID,
                0,
                false,
                true,
                false
            );
  
        } else {
            IBalanceManager(balanceManager).updateTraderPositions(
                _params.trader,
                _params.positionID,
                0,
                false,
                false,
                false
            );
            
        }

         emit PositionUpdated(
                _params.trader,
                _params.baseToken,
                 info.groupID,
                _params.positionID,
                _response.swappedBasePositionSize,
                _response.swappedQuotePositionSize,
                _response.fee,
                _response.pnlToBeRealized,
                _response.sqrtPriceAfterX96
            );

    }

    /**
     * @notice handles isolate position creation
     * @dev This function creates the isolated position and updates the variables accordingly
     * @param _params holds all the parameters required in position handler structure
     * @param _response this holds the response from swap manager 
     */
    function _handleIsolatePositions(
        InternalPositionHandlerParams memory _params,
        ISwapManager.SwapResponseParams memory _response,
        FundingGrowth memory fundingGrowth
    ) internal {
        // generate a new position id
        positionIDGenerator = positionIDGenerator + 1;
        uint256 positionId = positionIDGenerator;

        // updates the trader positions
        IBalanceManager(balanceManager).updateTraderPositions(
            _params.trader,
            positionId,
            _params.collateralForPosition,
            false,
            false,
            true
        );

        // updates the trader position info
        IBalanceManager(balanceManager).updateTraderPositionInfo(
            _params.trader,
            _params.baseToken,
            positionId,
            _response.swappedBasePositionSize,
            _response.swappedQuotePositionSize-(_response.fee.toInt256()), // CH fee charged in quote ammount
            0
        );

        IBalanceManager(balanceManager).updateTwPremiumGrowthGlobal(
            positionId,
            fundingGrowth.twPremiumX96
        );

        //checks for the collateral
        _checkCollateralRequirement(_params.trader, positionId);

        //emits an event
        emit PositionUpdated(
            _params.trader,
            _params.baseToken,
            0,
            positionId,
            _response.swappedBasePositionSize,
            _response.swappedQuotePositionSize,
            _response.fee,
            _response.pnlToBeRealized,
            _response.sqrtPriceAfterX96
        );

    }


     /**
     * @notice handles the creation of group and its position
     * @dev This function creates the cross margin group position and updates the variables accordingly
     * @param _params holds all the parameters required in position handler structure
     * @param _response this holds the response from swap manager 
     */
    function _handleGroupPositions(
        InternalPositionHandlerParams memory _params,
        ISwapManager.SwapResponseParams memory _response,
        FundingGrowth memory fundingGrowth
    ) internal {
        uint256 positionId;
        uint256 groupId;
        int256 pnlToBeRealized;
        bool marketPresent;

        // if wanted to create a new group then generate a new group id
        if (_params.isNewGroup) {
            groupIDGenerator = groupIDGenerator + 1;
            groupId = groupIDGenerator;
        } else {

            IBalanceManager.GroupInfo memory groupInfo;
            if(_params.isDefaultGroup){
                // fetched the default group id
                groupId=IBalanceManager(balanceManager).getDefaultGroupForTrader(_params.trader);

                // if no default group id is generated then generate and update
                if(groupId==0){
                    groupIDGenerator = groupIDGenerator + 1;
                    groupId = groupIDGenerator;
                    IBalanceManager(balanceManager).updateTraderDefaultGroupID(_params.trader,groupId);
                }

                //fetch group details
                groupInfo = IBalanceManager(
                    balanceManager
                ).getGroupInfo(groupId);
            }else{
                 // get group ids check validity of the entered group id
                groupInfo = IBalanceManager(
                    balanceManager
                ).getGroupInfo(_params.groupId);

                //OddzClearingHouse : Invalid Group ID
                require(groupInfo.trader==_params.trader, "OCH:IG");
                groupId = _params.groupId;
            }

            // check if this market position is already present or not
            // if yes then fetch psition id of that position
            IBalanceManager.GroupPositionsInfo[]
                memory groupPositionsInfo = groupInfo.groupPositions;
            for (uint256 i = 0; i < groupPositionsInfo.length; i++) {
                if (groupPositionsInfo[i].baseToken == _params.baseToken) {
                    marketPresent = true;
                    positionId = groupPositionsInfo[i].positionID;
                }
            }
        }
        // if market is not present in the group then create a new position id
        if (!marketPresent) {
            positionIDGenerator = positionIDGenerator + 1;
            positionId = positionIDGenerator;

            //update the position info
            IBalanceManager(balanceManager).updateTraderPositionInfo(
                _params.trader,
                _params.baseToken,
                positionId,
                _response.swappedBasePositionSize,
                _response.swappedQuotePositionSize-(_response.fee.toInt256()),
                groupId
            );

            IBalanceManager(balanceManager).updateTwPremiumGrowthGlobal(
                positionId,
                fundingGrowth.twPremiumX96
            );

            // updates trader position.As it is new position
            IBalanceManager(balanceManager).updateTraderPositions(
                _params.trader,
                positionId,
                _params.collateralForPosition,
                false,
                true,
                true
            );

            //update group info
            IBalanceManager(balanceManager).updateTraderGroups(
                _params.trader,
                _params.baseToken,
                positionId,
                groupId,
                _params.collateralForPosition,
                _params.isNewGroup,
                false,
                true
            );
        } else {

            _settleFunding(positionId,fundingGrowth);

            // when merging the position , it will check if the existing position is being reduced if yes then calculates PnL
            if(_response.swappedBasePositionSize!=0){
                pnlToBeRealized=ISwapManager(swapManager).getPnLToBeRealized(
                    positionId,
                    _response.swappedBasePositionSize,
                    _response.swappedQuotePositionSize
                );
            }

            //if market is present , then use exiting position
            // merge the current position with existing one
            // update the trader position info
            IBalanceManager(balanceManager).updateTraderPositionInfo(
                _params.trader,
                _params.baseToken,
                positionId,
                _response.swappedBasePositionSize,
                _response.swappedQuotePositionSize-(_response.fee.toInt256()),
                groupId
            );

            // fetch the position info
            IBalanceManager.PositionInfo memory positionInfo = IBalanceManager(
                balanceManager
            ).getPositionInfo(positionId);

            // check if the position has some balance or not

            if(IBalanceManager(balanceManager).getTakerBasePositionSize(positionId) == 0){
                //BalanceManager:Inconsistent quote and realizedPnL
                //Inconsistent quote and  realizedPnL
                require(pnlToBeRealized.abs() <= positionInfo.takerQuoteSize.abs(), "OCH:IQAR");
                
                pnlToBeRealized=positionInfo.takerQuoteSize;

                if (_response.pnlToBeRealized != 0 || pnlToBeRealized !=0) {
                    IBalanceManager(balanceManager).settleQuoteToOwedRealizedPnl(
                        positionId,
                        _response.pnlToBeRealized + pnlToBeRealized
                    );
                }
                
                //updates trader groups if there is no position
                IBalanceManager(balanceManager).updateTraderGroups(
                    _params.trader,
                    _params.baseToken,
                    positionId,
                    groupId,
                    _params.collateralForPosition,
                    false,
                    true,
                    false
                );
            }else{
                if (_response.pnlToBeRealized != 0 || pnlToBeRealized !=0) {
                    IBalanceManager(balanceManager).settleQuoteToOwedRealizedPnl(
                        positionId,
                        _response.pnlToBeRealized + pnlToBeRealized
                    );
                }

                //if position has some balance then update trader positions.Updates collateral 
                IBalanceManager(balanceManager).updateTraderPositions(
                    _params.trader,
                    positionId,
                    _params.collateralForPosition,
                    true,
                    true,
                    true
                );

                // updates group info
                IBalanceManager(balanceManager).updateTraderGroups(
                    _params.trader,
                    _params.baseToken,
                    positionId,
                    groupId,
                    _params.collateralForPosition,
                    _params.isNewGroup,
                    true,
                    true
                );
            }
        }


        // checks the collateral requirement
        _checkGroupCollateralRequirement(_params.trader, groupId);
        
        //emits an event
        emit PositionUpdated(
            _params.trader,
            _params.baseToken,
            groupId,
            positionId,
            _response.swappedBasePositionSize,
            _response.swappedQuotePositionSize,
            _response.fee,
            _response.pnlToBeRealized+pnlToBeRealized,
            _response.sqrtPriceAfterX96
        );
    }

    /**
     * @notice it handles the impermanent position(IP) generated from removing liquidity
     * @dev This function either creates a permanent position or closes the impermanent position
     * @param maker address of the trader who is removing liquidity
     * @param params holds all the parameters required in removing liquidity
     * @param response this holds the response from order manager 
     */
    function _settleLiquidityGeneratedPosition(
        address maker,
        RemoveLiquidityParams memory params,
        IOrderManager.RemoveLiquidityResponse memory response,
         FundingGrowth memory fundingGrowth 
    ) internal {
        if (!params.isClose) {
            // if position is going to open but takerBaseAmount is not sufficient so leave position creation
            if (response.takerBaseAmount.abs() > _DUST) {
                InternalPositionHandlerParams
                    memory internalParams = InternalPositionHandlerParams({
                        trader: maker,
                        baseToken: params.baseToken,
                        isIsolate: params.isIsolate,
                        isDefaultGroup:params.isDefaultGroup,
                        groupId: params.groupID,
                        isNewGroup: false,
                        collateralForPosition: params.collateralForPosition
                    });

                ISwapManager.SwapResponseParams memory _response = ISwapManager
                    .SwapResponseParams({
                        baseAmount: 0, //not being used in internal position handler function so putting as 0
                        quoteAmount: 0,
                        swappedBasePositionSize: response.takerBaseAmount,
                        swappedQuotePositionSize: response.takerQuoteAmount,
                        fee: 0, // settle fee amount to maker's ownedPnl
                        insuranceFee: 0,  // there is no trading fee as it already in pool so insurance fee will be zero
                        tick: 0,
                        pnlToBeRealized: 0,
                        sqrtPriceAfterX96: 0
                    });
                if (params.isIsolate && params.positionID==0) {
                    _handleIsolatePositions(internalParams, _response,fundingGrowth);
                } else if (params.isIsolate && params.positionID !=0) {

                    IBalanceManager.PositionInfo memory info = IBalanceManager(balanceManager)
                        .getPositionInfo(params.positionID);
                   

                    require(
                        info.trader==maker,
                        //OddzClearingHouse:Invalid position id for the trader
                        "OCH:IP"
                    );
                    
                    require(
                        info.groupID==0,
                        //OddzClearingHouse: Selected isolate position but given groupped position
                        //Not valid position
                        "OCH: NV"
                    );

                    require(
                        //OddzClearingHouse :Different markets
                        //
                        info.baseToken == params.baseToken , "OCH:DM"
                    );

                    _settleFunding(params.positionID, fundingGrowth);

                    int256 pnlToBeRealized;
                    // when merging the position , it will check if the existing position is being reduced if yes then calculates PnL
                    if(response.takerBaseAmount!=0){
                        pnlToBeRealized=ISwapManager(swapManager).getPnLToBeRealized(
                            params.positionID,
                            response.takerBaseAmount,
                            response.takerQuoteAmount
                        );
                    }

                    IBalanceManager(balanceManager).settleBalanceAndDeregister(
                        params.positionID,
                        response.takerBaseAmount,
                        response.takerQuoteAmount,
                        pnlToBeRealized
                    );
                } else if (!params.isIsolate && params.groupID != 0) {
                    _handleGroupPositions(internalParams, _response,fundingGrowth);
                } else if (!params.isIsolate && (params.groupID == 0) ){
                    if(!params.isDefaultGroup){
                        internalParams.isNewGroup = true;
                    }
                    _handleGroupPositions(internalParams, _response,fundingGrowth);
                }
            } else {
                // if position is going to open but takerBaseAmount is not sufficient so settle taker QuoteAmount as PnL in main collateral balance
                if (response.takerQuoteAmount.abs() > _DUST) {
                    IBalanceManager(balanceManager).settleLiquidityPnL(
                        maker,
                        response.takerQuoteAmount,
                        0,
                        false
                    );
                }
            }
        } else {
            // if position is going to close.
            if (response.takerBaseAmount.abs() > _DUST) {
                // if takerBaseAmount is + then  current position is long so open a short position and vice versa
                bool isShort = response.takerBaseAmount > 0;
                ISwapManager.SwapParams memory _swapParams = ISwapManager
                    .SwapParams({
                        trader: maker,
                        baseToken: params.baseToken,
                        isShort: isShort,
                        isExactInput: isShort,
                        specifiedAmount: response.takerBaseAmount.abs(),  // absolute amount of base amount.
                        isClosingPosition: true,
                        positionID: 0,
                        sqrtPriceLimitX96: 0
                    });
                
                // swaps
                (, int256 swappedQuoteSize , uint256 feesAmount,uint256 insuranceFee) = ISwapManager(swapManager)
                    .liquidityPositionSwap(_swapParams);

                // insurance fees always have to be updated to insurance contract.
                IBalanceManager(balanceManager).updateInsuranceManagerFees(insuranceFee.toInt256());

                //settle the PnL from impermanent position
                IBalanceManager(balanceManager).settleLiquidityPnL(
                    maker,
                    response.takerQuoteAmount,
                    swappedQuoteSize-(feesAmount.toInt256()),
                    true
                );

                // emit an event on opening a position just like normal position and closing.But position id in this case will be 0
                emit PositionUpdated(
                    maker,
                    params.baseToken,
                    0,
                    0,
                    response.takerBaseAmount.neg256(),
                    swappedQuoteSize,
                    0,
                    swappedQuoteSize + response.takerQuoteAmount,
                    0
                );
            } else {
                // is position size is not sufficient then settle quote amount as PnL in the main collateral balance
                IBalanceManager(balanceManager).settleLiquidityPnL(
                    maker,
                    response.takerQuoteAmount,
                    0,
                    false
                );
            }
        }
    }

    /**@notice for calculating funding payment amount for position and settling it in realized Pnl
    *@param _positionId position id
    *@param _fundingGrowth updated funding growth variables
     */
    function _settleFunding(
        uint256 _positionId,
        FundingGrowth memory _fundingGrowth 
        )internal{
             int256 fundingPayment=ISwapManager(swapManager).updateFundingGrowth(
                _positionId,
                _fundingGrowth.twPremiumX96,
                _fundingGrowth.twPremiumDivBySqrtPriceX96
            );

            if (fundingPayment != 0) {
                IBalanceManager(balanceManager).updateOwedRealizedPnl(_positionId, fundingPayment.neg256());
                emit FundingPaymentSettled(_positionId, fundingPayment);
            }

           
            IBalanceManager(balanceManager).updateTwPremiumGrowthGlobal(
                _positionId,
                _fundingGrowth.twPremiumX96
            );
    }


    /**@notice for calculating funding growth variables if position id >0 then calculates funding payment and settles it in realized PnL
    *@param _positionId position id
    *@param _baseToken base token
    *@param  _fundingGrowth funding growth variables
     */
    function _settlePositionFunding(uint256 _positionId, address _baseToken)
        internal
        returns (FundingGrowth memory _fundingGrowth){

        int256 fundingPayment;
        int256 _twPremiumX96;
        int256 _twPremiumDivBySqrtPriceX96;
        (fundingPayment, _twPremiumX96, _twPremiumDivBySqrtPriceX96) = ISwapManager(swapManager).settleFunding(_positionId,_baseToken);

        if (fundingPayment != 0) {
            IBalanceManager(balanceManager).updateOwedRealizedPnl(_positionId, fundingPayment.neg256());
            emit FundingPaymentSettled(_positionId, fundingPayment);
        }

        if(_positionId>0){
            IBalanceManager(balanceManager).updateTwPremiumGrowthGlobal(
                _positionId,
                _twPremiumX96
            );
        }

        _fundingGrowth =FundingGrowth({
            twPremiumX96:_twPremiumX96,
            twPremiumDivBySqrtPriceX96:_twPremiumDivBySqrtPriceX96
        });
        
    }

    /**@notice for calculating funding growth variables , 
    * funding payment amount of liquidity's impermanent position and settling it in realized Pnl
    *@param _baseToken base token
    *@param _orderId order id
    *@param  _fundingGrowth funding growth variables
     */
    function _settleLiquidityPositionFunding( address _baseToken,bytes32 _orderId)
        internal
        returns(FundingGrowth memory _fundingGrowth){
        
        
        int256 fundingPayment;
        int256 _twPremiumX96;
        int256 _twPremiumDivBySqrtPriceX96;
        (fundingPayment, _twPremiumX96, _twPremiumDivBySqrtPriceX96) = ISwapManager(swapManager).settleLiquidityPositionFunding(_baseToken,_orderId);

        if (fundingPayment != 0) {
            IOrderManager(orderManager).updateLiquidityPositionOwedRealizedPnl(_orderId, fundingPayment.neg256());
            emit LiquidityFundingPaymentSettled(_orderId, fundingPayment);
        }

        IOrderManager(orderManager).updateTwPremiumGrowthGlobal(
            _orderId,
            _twPremiumX96
        );

        _fundingGrowth =FundingGrowth({
            twPremiumX96:_twPremiumX96,
            twPremiumDivBySqrtPriceX96:_twPremiumDivBySqrtPriceX96
        });
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
            //OddzClearingHouse : Not enough collateral
            "OCH:NEC"
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
             //OddzClearingHouse : Not enough collateral
            "OCH:NEC"
        );
    }

    /**
     * @notice Checks if there is enough collateral or not for a liquidity order
     * @param _trader The Address of the trader
     * @param _baseToken base token address
     * @param _orderID ordder id for which we are checking the collateral
     */
    function _checkLiquidityCollateralRequirement(
        address _trader,
        address _baseToken,
        bytes32 _orderID
    ) internal view {
        require(
            IOddzVault(oddzVault).getLiquidityPositionCollateralByRatio(
                _trader,
                _baseToken,
                _orderID,
                IOddzConfig(oddzConfig).initialMarginRatio()
            ) >= 0,
             //OddzClearingHouse : Not enough collateral
            "OCH:NEC"
        );
    }
    
    /**
     * @notice this function update the trader volume
     * @param _trader The Address of the trader
     * @param _specifiedAmount trader volume 
     */
    function _updateTraderVolume(
        address _trader, 
        uint256 _specifiedAmount) internal 
    {
        IVolumeManager(volumeManager).updateTraderVolume(_trader,_specifiedAmount);
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
                        "OCH :RLOS"

                    );
                } else {
                    require(
                        _baseAmount <= _oppositeBoundAmount,
                        //requested more on short
                        "OCH :RMOS"
                    );
                }
            } else {
                if (_isExactInput) {
                    require(
                        _baseAmount >= _oppositeBoundAmount,
                        //received less on long
                        "OCH : RLOL"

                    );
                } else {
                    require(
                        _quoteAmount <= _oppositeBoundAmount,
                        //requested more on long
                        "OCH :RMOL"

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
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
pragma solidity >=0.5.0;

import './IUniswapV3PoolImmutables.sol';
import './IUniswapV3PoolState.sol';
import './IUniswapV3PoolDerivedState.sol';
import './IUniswapV3PoolActions.sol';
import './IUniswapV3PoolOwnerActions.sol';
import './IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

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

import  "@openzeppelin/contracts-upgradeableV2/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

interface IVolumeManager {

    /**
     * @notice this function update the trader volume 
     * @param _trader The Address of the trader
     * @param _traderVolume trader volume 
     */
    function updateTraderVolume(
        address _trader,
        uint256  _traderVolume
    )  external;
    
    /**
     * @notice get trader total volume accumulated so far.
     * @param _trader address of trader.
     */
    function fetchLast30DaysVolume(address _trader) external view returns(uint256 totalVolume);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
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

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
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