// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IAAOption.sol";
import "./interface/IAAOptionMarket.sol";
import "./interface/IAAOptionRouter.sol";
import "./interface/IAAMOptionMarket.sol";
import "./interface/IAAOptionBase.sol";
import "./interface/ITokenDecimals.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AAOptionRouter is AccessControl, IAAOptionRouter ,ERC1155Receiver{

    IAAOptionBase internal routerProof;

    IAAOptionBase internal routerOption;

    using Counters for Counters.Counter;

    Counters.Counter private _routerOptionIdCounter;

    // key : AAOptionMarket address
    mapping(address => RouterMarketInfo) public marketInfo;

    // aao market => aao optionId => routerOptionId
    mapping(address => mapping(uint256 => uint256) ) public routerOptionIdInfo;

    // routerOptionId => RouterOptionDetailInfo(aao market,aao optionId,listingId)
    mapping(uint256 => RouterOptionDetailInfo) public routerOptionDetail;

    // address (aam/aao) =》 routerOptionId =>lockAmount:user lock record
    mapping(address => mapping(uint256 => uint256)) public lockInfo;

    // address (aam/aao) =》 routerOptionId =>optionAmount:user option record
    mapping(address => mapping(uint256 => uint256)) public optionInfo;

    // routerOptionId =>SettleInfo
    mapping(uint256 => SettleInfo) public settleInfo;

    bytes32 public constant ID_ROLE = keccak256("ID_ROLE");

    struct DealInfoDto {
        RouterMarketInfo tempMarketInfo;
        IAAOption.AAOptionDetail optionDetail;
        uint256 aaoAmount;
        uint256 aaoCost;
        uint256 routerOptionId;
        uint256 preCost;
        uint256 slippageAmount;
        uint256 lockQuoteAmount;
        uint256 aamLockQuote;
    }

    constructor(
        IAAOptionBase _routerProof,
        IAAOptionBase _routerOption
    ) {
        routerProof = _routerProof;
        routerOption = _routerOption;
        // ID increment begin 1
        _routerOptionIdCounter.increment();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ID_ROLE, msg.sender);
    }

    function createRouterId(address _market, uint256 _optionId,uint256 _listingId,uint256 _boardId) public override onlyRole(ID_ROLE) returns(uint256){
        uint256 _routerOptionId = routerOptionIdInfo[_market][_optionId];
        if(_routerOptionId <= 0){
            _routerOptionId = _routerOptionIdCounter.current();
            _routerOptionIdCounter.increment();
            routerOptionIdInfo[_market][_optionId] = _routerOptionId;
            routerOptionDetail[_routerOptionId] = RouterOptionDetailInfo(_market,_optionId,_listingId,_boardId);
            IAAOption.AAOptionDetail memory optionDetail = IAAOption(marketInfo[_market].aaOption).getOptionDetail(_optionId);
            emit RouterOptionIdCreated(_routerOptionId,_market,_optionId,_listingId,_boardId,optionDetail.expireTime,optionDetail.strikePrice,optionDetail.optionType);
        }
        return _routerOptionId;
    }

    function createRouterIdBatch(address[] memory _markets, uint256[] memory _optionIds,uint256[]  memory _listingIds,uint256[]  memory _boardIds) public override onlyRole(ID_ROLE) returns(uint256[] memory){
        uint256[] memory ids = new uint256[](_markets.length);
        for (uint256 i = 0; i < _markets.length; i++) {
            ids[i] = createRouterId(_markets[i],_optionIds[i],_listingIds[i],_boardIds[i]);
        }
        return ids;
    }


    function settingMarketInfo(RouterMarketInfo memory _marketInfo,address market) public override onlyRole(ID_ROLE){
        require(market != address(0),"must be not null");
        marketInfo[market] = _marketInfo;
    }



    function preDealInfo(
        AAOptionMsg[] memory optionMsg,
        AAMMsg memory aamMsg,
        CommonMsg memory commonMsg
    ) internal view returns (DealInfoDto memory){
        RouterMarketInfo memory tempMarketInfo = marketInfo[commonMsg.market];
        IAAOption.AAOptionDetail memory optionDetail = IAAOption(tempMarketInfo.aaOption).getOptionDetail(commonMsg.optionId);
        (uint256 aaoAmount, uint256 aaoCost) = _calcAmount(optionMsg,tempMarketInfo.baseAsset);
        uint256 routerOptionId = routerOptionIdInfo[commonMsg.market][optionDetail.id];
        require(aaoAmount + aamMsg.amount == commonMsg.amount, "order amount not match");
        require(aamMsg.slippage <= 1e4, "slippage must be le 1 (10000)");
        uint256 preCost = aamMsg.amount * aamMsg.price / (10 ** ITokenDecimals(address(tempMarketInfo.baseAsset)).decimals());
        uint256 slippageAmount = aaoCost + preCost * (aamMsg.slippage + 1e4) / 1e4;
        require(optionDetail.id > 0,"option id error");
        uint256 lockQuoteAmount = (commonMsg.amount * optionDetail.strikePrice / (10 ** ITokenDecimals(address(tempMarketInfo.baseAsset)).decimals()));
        uint256 aamLockQuote = (aamMsg.amount * optionDetail.strikePrice / (10 ** ITokenDecimals(address(tempMarketInfo.baseAsset)).decimals()));
        return DealInfoDto(tempMarketInfo,optionDetail,aaoAmount,aaoCost,routerOptionId,preCost,slippageAmount,lockQuoteAmount,aamLockQuote);
    }

    /**
   * @dev Opens a position, which may be long call, long put, short call or short put.
   * @param optionMsg struct
     *  maker.
     *  amount:aggregator match amount for maker
     *  signAmount : maker sign with amount (signAmount must be ge match amount)
     *  signTime : maker sign with time (signTime must be gt currentTime)
     *  price : maker's price and sign with price
     *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,chainId,innerNonce)
   * @param aamMsg struct
     * amount; // aam match amount
     * price; // aam avg price
     * slippage; // aam slippage 10000 means 1,so 10 means 0.001,1 means 0.0001
     * listingId; // aam option id expireTime,strike must be equal aaoption id
   * @param commonMsg struct
     * optionId; // aaoption id
     * amount; // order amount ,means total amount
     * tradeType; //LONG SHORT
     * market; // aaoption market address
   */
    function openPosition(
        AAOptionMsg[] memory optionMsg,
        AAMMsg memory aamMsg,
        CommonMsg memory commonMsg
    ) external override returns (uint256 totalCost){
        IAAMOptionMarket.TradeType aamType;
        PositionType positionType;
        DealInfoDto memory dealInfoDto = preDealInfo(optionMsg,aamMsg,commonMsg);
        if (commonMsg.tradeType == TradeType.LONG) {
            positionType = PositionType.OPEN_LONG;
            require(IERC20(dealInfoDto.tempMarketInfo.quoteAsset).transferFrom(msg.sender, address(this), dealInfoDto.slippageAmount), "QuoteTransferFailed");
            routerOption.mint(msg.sender,dealInfoDto.routerOptionId,commonMsg.amount,"");
            _checkAllowance(dealInfoDto.tempMarketInfo.quoteAsset,commonMsg.market,dealInfoDto.aaoCost);
            _checkAllowance(dealInfoDto.tempMarketInfo.quoteAsset, dealInfoDto.tempMarketInfo.aamMarket, dealInfoDto.preCost * 2);
            if(dealInfoDto.optionDetail.optionType){
                aamType = IAAMOptionMarket.TradeType.LONG_CALL;
                _callRouter(dealInfoDto,commonMsg,aamMsg);
            }else{
                aamType = IAAMOptionMarket.TradeType.LONG_PUT;
                _putRouter(dealInfoDto,commonMsg);
            }
        } else {
            positionType = PositionType.OPEN_SHORT;
            if(dealInfoDto.optionDetail.optionType){
                require(IERC20(dealInfoDto.tempMarketInfo.baseAsset).transferFrom(msg.sender, address(this), commonMsg.amount), "BaseTransferFailed");
                _checkAllowance(dealInfoDto.tempMarketInfo.baseAsset,commonMsg.market,dealInfoDto.aaoAmount);
                routerProof.mint(msg.sender,dealInfoDto.routerOptionId,commonMsg.amount,"");
                aamType = IAAMOptionMarket.TradeType.SHORT_CALL;
                _checkAllowance(dealInfoDto.tempMarketInfo.baseAsset, dealInfoDto.tempMarketInfo.aamMarket, aamMsg.amount);
                _callRouter(dealInfoDto,commonMsg,aamMsg);

            }else{
                require(IERC20(dealInfoDto.tempMarketInfo.quoteAsset).transferFrom(msg.sender, address(this), dealInfoDto.lockQuoteAmount), "QuoteTransferFailed");
                _checkAllowance(dealInfoDto.tempMarketInfo.quoteAsset,commonMsg.market,dealInfoDto.lockQuoteAmount);
                routerProof.mint(msg.sender,dealInfoDto.routerOptionId,dealInfoDto.lockQuoteAmount,"");
                _putRouter(dealInfoDto,commonMsg);
                aamType = IAAMOptionMarket.TradeType.SHORT_PUT;
                _checkAllowance(dealInfoDto.tempMarketInfo.quoteAsset, dealInfoDto.tempMarketInfo.aamMarket, dealInfoDto.aamLockQuote);
            }
        }
        if(dealInfoDto.aaoAmount > 0){
            totalCost += IAAOptionMarket(commonMsg.market).openPosition(optionMsg,commonMsg.optionId,dealInfoDto.aaoAmount,commonMsg.tradeType);
        }
        if(aamMsg.amount > 0 && aamMsg.listingId > 0){
            require(routerOptionDetail[dealInfoDto.routerOptionId].listingId == aamMsg.listingId, "listingId not match");
            uint256 _totalCost = IAAMOptionMarket(dealInfoDto.tempMarketInfo.aamMarket).openPosition(aamMsg.listingId,aamType,aamMsg.amount);
            if(commonMsg.tradeType == TradeType.LONG){
                require((dealInfoDto.preCost * (aamMsg.slippage + 1e4) / 1e4) >= _totalCost, "out of slippage");// out
                // back surplus quote amount
                require(IERC20(dealInfoDto.tempMarketInfo.quoteAsset).transfer(msg.sender, dealInfoDto.slippageAmount - dealInfoDto.aaoCost - _totalCost), "QuoteTransferFailed");
            }else{
                require((dealInfoDto.preCost * (1e4 - aamMsg.slippage) / 1e4) <= _totalCost, "out of slippage");// in
            }
            totalCost += _totalCost;
        }
        emit PositionOpened(msg.sender, commonMsg.tradeType, dealInfoDto.routerOptionId, commonMsg.amount, totalCost);
        emit PositionUpdated(msg.sender, positionType, dealInfoDto.routerOptionId, commonMsg.amount, totalCost);
    }

    function _callRouter(DealInfoDto memory dealInfoDto,CommonMsg memory commonMsg,AAMMsg memory aamMsg) internal {
        if(commonMsg.tradeType == TradeType.LONG){
            optionInfo[commonMsg.market][dealInfoDto.routerOptionId] += dealInfoDto.aaoAmount;
            optionInfo[dealInfoDto.tempMarketInfo.aamMarket][dealInfoDto.routerOptionId] += aamMsg.amount;
        }else{
            lockInfo[commonMsg.market][dealInfoDto.routerOptionId] += dealInfoDto.aaoAmount;
            lockInfo[dealInfoDto.tempMarketInfo.aamMarket][dealInfoDto.routerOptionId] += aamMsg.amount;
        }
    }

    function _putRouter(DealInfoDto memory dealInfoDto,CommonMsg memory commonMsg) internal {
        if(commonMsg.tradeType == TradeType.LONG){
            optionInfo[commonMsg.market][dealInfoDto.routerOptionId] += (dealInfoDto.lockQuoteAmount - dealInfoDto.aamLockQuote);
            optionInfo[dealInfoDto.tempMarketInfo.aamMarket][dealInfoDto.routerOptionId] += dealInfoDto.aamLockQuote;
        }else{
            lockInfo[commonMsg.market][dealInfoDto.routerOptionId] += (dealInfoDto.lockQuoteAmount - dealInfoDto.aamLockQuote);
            lockInfo[dealInfoDto.tempMarketInfo.aamMarket][dealInfoDto.routerOptionId] += dealInfoDto.aamLockQuote;
        }
    }

    function _checkAllowance(address _erc20, address _spender, uint256 amount) internal {
        uint256 allowAmount = IERC20(_erc20).allowance(address(this),_spender);
        if(allowAmount <= amount){
            IERC20(_erc20).approve(_spender,type(uint256).max);
        }
    }

    function _checkApprove(address _erc1155, address _spender) internal {
        bool _approve = IERC1155(_erc1155).isApprovedForAll(address(this), _spender);
        if(!_approve){
            IERC1155(_erc1155).setApprovalForAll(_spender,!_approve);
        }
    }

    function _calcAmount(AAOptionMsg[] memory optionMsg,address _base) internal view returns (uint256 aaoAmount, uint256 aaoCost){
        uint256 step;
        while(step < optionMsg.length){
            aaoAmount += optionMsg[step].amount;
            aaoCost += ( optionMsg[step].amount * optionMsg[step].price / (10 ** ITokenDecimals(address(_base)).decimals()) );
            step++;
        }
    }

    /**
   * @dev close a position, which may be long call, long put, short call or short put.
   * @param optionMsg struct
     *  maker.
     *  amount:aggregator match amount for maker
     *  signAmount : maker sign with amount (signAmount must be ge match amount)
     *  signTime : maker sign with time (signTime must be gt currentTime)
     *  price : maker's price and sign with price
     *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,chainId,innerNonce)
   * @param aamMsg struct
     * amount; // aam match amount
     * price; // aam avg price
     * slippage; // aam slippage 10000 means 1,so 10 means 0.001,1 means 0.0001
     * listingId; // aam option id expireTime,strike must be equal aaoption id
   * @param commonMsg struct
     * optionId; // aaoption id
     * amount; // order amount ,means total amount
     * tradeType; //LONG SHORT
     * market; // aaoption market address
   */
    function closePosition(
        AAOptionMsg[] memory optionMsg,
        AAMMsg memory aamMsg,
        CommonMsg memory commonMsg
    ) external override returns (uint256 totalCost){
        IAAMOptionMarket.TradeType aamType;
        PositionType positionType;
        DealInfoDto memory dealInfoDto = preDealInfo(optionMsg,aamMsg,commonMsg);
        if (commonMsg.tradeType == TradeType.LONG) {
            positionType = PositionType.CLOSE_LONG;
            routerOption.burn(msg.sender,dealInfoDto.routerOptionId,commonMsg.amount);
            _checkApprove(dealInfoDto.tempMarketInfo.aaOption,commonMsg.market);
            _checkApprove(dealInfoDto.tempMarketInfo.aamOption,dealInfoDto.tempMarketInfo.aamMarket);
            if(dealInfoDto.optionDetail.optionType){
                aamType = IAAMOptionMarket.TradeType.LONG_CALL;
                optionInfo[commonMsg.market][dealInfoDto.routerOptionId] -= dealInfoDto.aaoAmount;
                optionInfo[dealInfoDto.tempMarketInfo.aamMarket][dealInfoDto.routerOptionId] -= aamMsg.amount;
            }else{
                aamType = IAAMOptionMarket.TradeType.LONG_PUT;
                optionInfo[commonMsg.market][dealInfoDto.routerOptionId] -= (dealInfoDto.lockQuoteAmount-dealInfoDto.aamLockQuote);
                optionInfo[dealInfoDto.tempMarketInfo.aamMarket][dealInfoDto.routerOptionId] -= dealInfoDto.aamLockQuote;
            }
        } else {
            positionType = PositionType.OPEN_SHORT;
            require(IERC20(dealInfoDto.tempMarketInfo.quoteAsset).transferFrom(msg.sender, address(this), dealInfoDto.slippageAmount), "QuoteTransferFailed");
            _checkAllowance(dealInfoDto.tempMarketInfo.quoteAsset, dealInfoDto.tempMarketInfo.aamMarket, dealInfoDto.preCost * 2);
            _checkAllowance(dealInfoDto.tempMarketInfo.quoteAsset, commonMsg.market, dealInfoDto.aaoCost);
            _checkApprove(dealInfoDto.tempMarketInfo.aamOption,dealInfoDto.tempMarketInfo.aamMarket);
            _checkApprove(dealInfoDto.tempMarketInfo.aaProof,commonMsg.market);
            if(dealInfoDto.optionDetail.optionType){
                lockInfo[commonMsg.market][dealInfoDto.routerOptionId] -= dealInfoDto.aaoAmount;
                lockInfo[dealInfoDto.tempMarketInfo.aamMarket][dealInfoDto.routerOptionId] -= aamMsg.amount;
                routerProof.burn(msg.sender,dealInfoDto.routerOptionId,commonMsg.amount);
                aamType = IAAMOptionMarket.TradeType.SHORT_CALL;
            }else{
                lockInfo[commonMsg.market][dealInfoDto.routerOptionId] -= (dealInfoDto.lockQuoteAmount - dealInfoDto.aamLockQuote);
                lockInfo[dealInfoDto.tempMarketInfo.aamMarket][dealInfoDto.routerOptionId] -= dealInfoDto.aamLockQuote;
                routerProof.burn(msg.sender,dealInfoDto.routerOptionId,dealInfoDto.lockQuoteAmount);
                aamType = IAAMOptionMarket.TradeType.SHORT_PUT;
            }
        }

        if(dealInfoDto.aaoAmount > 0){
            totalCost += IAAOptionMarket(commonMsg.market).closePosition(optionMsg,commonMsg.optionId,dealInfoDto.aaoAmount,commonMsg.tradeType);
        }

        if(aamMsg.amount > 0 && aamMsg.listingId > 0){
            require(routerOptionDetail[dealInfoDto.routerOptionId].listingId == aamMsg.listingId, "listingId not match");
            uint256 _totalCost = IAAMOptionMarket(dealInfoDto.tempMarketInfo.aamMarket).closePosition(aamMsg.listingId,aamType,aamMsg.amount);
            if(commonMsg.tradeType == TradeType.LONG){
                require((dealInfoDto.preCost * (1e4 - aamMsg.slippage) / 1e4) <= _totalCost , "out of slippage");// in
            }else{
                require(dealInfoDto.preCost * (aamMsg.slippage + 1e4) / 1e4 >= _totalCost, "out of slippage");// out
                // back surplus quote amount
                require(IERC20(dealInfoDto.tempMarketInfo.quoteAsset).transfer(msg.sender, dealInfoDto.slippageAmount - dealInfoDto.aaoCost - _totalCost), "QuoteTransferFailed");
            }
            totalCost += _totalCost;
        }

        if (commonMsg.tradeType == TradeType.LONG) {
            require(IERC20(dealInfoDto.tempMarketInfo.quoteAsset).transfer(msg.sender, totalCost), "QuoteTransferFailed");
        } else {
            if(dealInfoDto.optionDetail.optionType){
                require(IERC20(dealInfoDto.tempMarketInfo.baseAsset).transfer(msg.sender, commonMsg.amount), "BaseTransferFailed");
            }else{
                require(IERC20(dealInfoDto.tempMarketInfo.quoteAsset).transfer(msg.sender, dealInfoDto.lockQuoteAmount), "QuoteTransferFailed");
            }
        }
        emit PositionClosed(msg.sender, commonMsg.tradeType, dealInfoDto.routerOptionId, commonMsg.amount, totalCost);
        emit PositionUpdated(msg.sender, positionType, dealInfoDto.routerOptionId, commonMsg.amount, totalCost);
    }

    function _settleAAM(address _option, address _market, uint256 _listingId, IAAMOptionMarket.TradeType _type) internal {
        uint256 amount = IERC1155(_option).balanceOf(address(this), _listingId + uint256(_type));
        if(amount > 0){
            IAAMOptionMarket(_market).settleOptions(_listingId,_type);
        }
    }

    function _settleRouter(address _market, uint256 _optionId) internal {
        uint256 routerOptionId = routerOptionIdInfo[_market][_optionId];
        require(settleInfo[routerOptionId].routerOptionId <= 0,"must be unsettle option");
        RouterMarketInfo memory tempMarketInfo = marketInfo[_market];
        IAAOption.AAOptionDetail memory optionDetail = IAAOption(tempMarketInfo.aaOption).getOptionDetail(_optionId);
        uint256 beforeBaseBalance = IERC20(tempMarketInfo.baseAsset).balanceOf(address(this));
        uint256 beforeQuoteBalance = IERC20(tempMarketInfo.quoteAsset).balanceOf(address(this));
        _checkApprove(tempMarketInfo.aamOption,tempMarketInfo.aamMarket);
        _checkApprove(tempMarketInfo.aaOption,_market);
        _checkApprove(tempMarketInfo.aaProof,_market);
        (,uint256 amount) = IAAOptionMarket(_market).settleOptions(_optionId);
        uint256 afterAAOBaseBalance = IERC20(tempMarketInfo.baseAsset).balanceOf(address(this));
        uint256 afterAAOQuoteBalance = IERC20(tempMarketInfo.quoteAsset).balanceOf(address(this));
        if(routerOptionDetail[routerOptionId].listingId > 0){
            if(optionDetail.optionType){
                settleInfo[routerOptionId].profit += (afterAAOQuoteBalance - beforeQuoteBalance);
                settleInfo[routerOptionId].unlockAmount += (afterAAOBaseBalance - beforeBaseBalance);
                _settleAAM(tempMarketInfo.aamOption, tempMarketInfo.aamMarket, routerOptionDetail[routerOptionId].listingId, IAAMOptionMarket.TradeType.LONG_CALL);
                settleInfo[routerOptionId].profit += (IERC20(tempMarketInfo.quoteAsset).balanceOf(address(this)) - afterAAOQuoteBalance);
                _settleAAM(tempMarketInfo.aamOption, tempMarketInfo.aamMarket, routerOptionDetail[routerOptionId].listingId, IAAMOptionMarket.TradeType.SHORT_CALL);
                settleInfo[routerOptionId].unlockAmount += (IERC20(tempMarketInfo.baseAsset).balanceOf(address(this)) - afterAAOBaseBalance);
            }else{
                settleInfo[routerOptionId].profit += (afterAAOQuoteBalance-beforeQuoteBalance-amount);
                settleInfo[routerOptionId].unlockAmount += amount;
                _settleAAM(tempMarketInfo.aamOption, tempMarketInfo.aamMarket, routerOptionDetail[routerOptionId].listingId, IAAMOptionMarket.TradeType.LONG_PUT);
                uint256 afterLongPutBalance = IERC20(tempMarketInfo.quoteAsset).balanceOf(address(this));
                settleInfo[routerOptionId].profit += ( afterLongPutBalance - afterAAOQuoteBalance);
                _settleAAM(tempMarketInfo.aamOption, tempMarketInfo.aamMarket, routerOptionDetail[routerOptionId].listingId, IAAMOptionMarket.TradeType.SHORT_PUT);
                settleInfo[routerOptionId].unlockAmount += (IERC20(tempMarketInfo.quoteAsset).balanceOf(address(this)) - afterLongPutBalance);
            }
        }else{
            if(optionDetail.optionType){
                settleInfo[routerOptionId].profit += (afterAAOQuoteBalance - beforeQuoteBalance);
                settleInfo[routerOptionId].unlockAmount += (afterAAOBaseBalance - beforeBaseBalance);
            }else{
                settleInfo[routerOptionId].profit += (afterAAOQuoteBalance-beforeQuoteBalance-amount);
                settleInfo[routerOptionId].unlockAmount += amount;
            }
        }

        settleInfo[routerOptionId].routerOptionId = routerOptionId;
    }

    function settleOptions(address market,uint256 optionId) external override {
        RouterMarketInfo memory tempMarketInfo = marketInfo[market];
        IAAOption.AAOptionDetail memory optionDetail = IAAOption(tempMarketInfo.aaOption).getOptionDetail(optionId);
        require(optionDetail.expireTime <= block.timestamp,"must be expired");
        uint256 routerOptionId = routerOptionIdInfo[market][optionId];
        (, , , uint256 spotPrice) = IAAOptionMarket(market).optionLockPool(optionId);
        require(spotPrice > 0,"spot price must be gl 0");
        uint256 optionBalance = routerOption.balanceOf(msg.sender, routerOptionId);// long
        uint256 lockBalance = routerProof.balanceOf(msg.sender, routerOptionId);// short
        if(settleInfo[routerOptionId].routerOptionId <= 0){
            _settleRouter(market, optionId);
        }
        if(optionDetail.optionType){
            if(optionBalance > 0){
                //long call
                routerOption.burn(msg.sender, routerOptionId, optionBalance);
                require(IERC20(tempMarketInfo.quoteAsset).transfer(msg.sender, settleInfo[routerOptionId].profit * optionBalance/optionInfo[market][routerOptionId]), "QuoteTransferFailed");
            }
            // short call
            if(lockBalance > 0){
                routerProof.burn(msg.sender, routerOptionId, lockBalance);
                require(IERC20(tempMarketInfo.baseAsset).transfer(msg.sender, settleInfo[routerOptionId].unlockAmount * lockBalance/lockInfo[market][routerOptionId]), "BaseTransferFailed");
            }
        }else{
            // long put
            if(optionBalance > 0){
                routerOption.burn(msg.sender, routerOptionId, optionBalance);
                require(IERC20(tempMarketInfo.quoteAsset).transfer(msg.sender, settleInfo[routerOptionId].profit * optionBalance/optionInfo[market][routerOptionId]/optionDetail.strikePrice), "QuoteTransferFailed");
            }
//            short put
            if(lockBalance > 0){
                routerProof.burn(msg.sender, routerOptionId, lockBalance);
                require(IERC20(tempMarketInfo.quoteAsset).transfer(msg.sender, settleInfo[routerOptionId].unlockAmount * lockBalance/optionInfo[market][routerOptionId]), "QuoteTransferFailed");
            }
        }
        emit OptionsSettled(msg.sender,routerOptionId,optionBalance,lockBalance);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Receiver, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IAAOption is IERC1155{

    struct AAOptionDetail {
        uint256 id;
        uint256 expireTime;
        uint256 strikePrice;
        bool optionType;//{ true CALL, false PUT}
    }

    function currentId() external view returns (uint256);

    function getOptionDetail(uint256 id) external view returns (AAOptionDetail memory);

    function getOptionId(uint256 expireTime, uint256 strikePrice, bool optionType) external view returns (uint256);

    function listOptions(uint256 fromIndex, uint256 pageSize) external view returns (AAOptionDetail[] memory);

    function createOptionId(uint256 expireTime, uint256 strikePrice, bool optionType) external returns (uint256);

    function createOptionIdBatch(uint256[] memory expireTime, uint256[] memory strikePrice, bool[] memory optionType) external returns (uint256[] memory);

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external returns (uint256);

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external returns (uint256[] memory);

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

pragma solidity ^0.8.4;

import "./IAABaseData.sol";

interface IAAOptionMarket is IAABaseData{

  event PositionOpened(
    address indexed user,
    TradeType indexed tradeType,
    uint256 indexed optionId,
    uint256 amount,
    uint256 totalCost
  );

  event PositionClosed(
    address indexed user,
    TradeType indexed tradeType,
    uint256 indexed optionId,
    uint256 amount,
    uint256 totalCost
  );

  event OptionsSettled(
    address indexed user,
    uint256 indexed optionId,
    uint256 indexed optionAmount,
    uint256 lockAmount
  );

  function optionLockPool(uint256 optionId) external view returns (uint256, uint256, uint256, uint256);

  function makerNonce(address maker) external view returns (uint256);

  /**
   * @dev Opens a position, which may be long call, long put, short call or short put.
   * @param optionMsg struct
     *  maker.
     *  amount:aggregator match amount for maker
     *  signAmount : maker sign with amount (signAmount must be ge match amount)
     *  signTime : maker sign with time (signTime must be gt currentTime)
     *  price : maker's price and sign with price
     *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,chainId)
   * @param optionId: option(time,strike,call/put) id
   * @param amount: total amount (order amount)
   * @param tradeType: LONG SHORT
   */
  function openPosition(
    AAOptionMsg[] memory optionMsg,
    uint256 optionId,
    uint256 amount,
    TradeType tradeType
  ) external returns (uint256 totalCost);

  /**
   * @dev close a position, which may be long call, long put, short call or short put.
   * @param optionMsg struct
     *  maker.
     *  amount:aggregator match amount for maker
     *  signAmount : maker sign with amount (signAmount must be ge match amount)
     *  signTime : maker sign with time (signTime must be gt currentTime)
     *  price : maker's price and sign with price
     *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,chainId)
   * @param optionId: option(time,strike,call/put) id
   * @param amount: total amount (order amount)
   * @param tradeType: LONG SHORT
   */
  function closePosition(
    AAOptionMsg[] memory optionMsg,
    uint256 optionId,
    uint256 amount,
    TradeType tradeType
  ) external returns (uint256 totalCost);

  function settleOptions(uint256 optionId) external returns (uint256 profit,uint256 amount);

  function storeOptionsPrice(uint256 optionId) external returns(uint256);

  function checkSign(AAOptionMsg memory optionMsg, uint256 optionId, TradeType tradeType) external;
}

pragma solidity ^0.8.4;

import "./IAABaseData.sol";

interface IAAOptionRouter is IAABaseData{

  event PositionOpened(
    address indexed user,
    TradeType indexed tradeType,
    uint256 indexed optionId,
    uint256 amount,
    uint256 totalCost
  );

  event PositionClosed(
    address indexed user,
    TradeType indexed tradeType,
    uint256 indexed optionId,
    uint256 amount,
    uint256 totalCost
  );

  enum PositionType {OPEN_LONG, OPEN_SHORT, CLOSE_LONG, CLOSE_SHORT}

  event PositionUpdated(
    address indexed user,
    PositionType indexed postionType,
    uint256 indexed optionId,
    uint256 amount,
    uint256 totalCost
  );

  event OptionsSettled(
    address indexed user,
    uint256 indexed optionId,
    uint256 indexed optionAmount,
    uint256 lockAmount
  );


  struct AAMMsg{
    uint256 amount; // aam match amount
    uint256 price; // aam avg price
    uint256 slippage; // aam slippage 10000 means 1,so 10 means 0.001,1 means 0.0001
    uint256 listingId; // aam option id expireTime,strike must be equal aaoption id
  }

  struct CommonMsg{
    uint256 optionId; // aaoption id
    uint256 amount; // order amount ,means total amount
    TradeType tradeType; //LONG SHORT
    address market; // aaoption market address
  }

  struct RouterMarketInfo{
    address baseAsset;
    address quoteAsset;
    address aaOption;
    address aaProof;
    address aamOption;
    address aamMarket;
  }

  struct SettleInfo {
    uint256 routerOptionId;
    uint256 profit;
    uint256 unlockAmount;
  }

  struct RouterOptionDetailInfo{
    address market; // aao market
    uint256 optionId; // aao option
    uint256 listingId; // aam listingId
    uint256 boardId; // aam boardId
  }

  event RouterOptionIdCreated(
    uint256 indexed routerId,
    address indexed market, // aao market
    uint256 indexed optionId, // aao option
    uint256 listingId, // aam listingId
    uint256 boardId, // aam boardId
    uint256 expireTime,
    uint256 strikePrice,
    bool optionType
  );

  /**
   * @dev Opens a position, which may be long call, long put, short call or short put.
   * @param optionMsg struct
     *  maker.
     *  amount:aggregator match amount for maker
     *  signAmount : maker sign with amount (signAmount must be ge match amount)
     *  signTime : maker sign with time (signTime must be gt currentTime)
     *  price : maker's price and sign with price
     *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,chainId)
   * @param aamMsg struct
     * amount; // aam match amount
     * price; // aam avg price
     * slippage; // aam slippage 10000 means 1,so 10 means 0.001,1 means 0.0001
     * listingId; // aam option id expireTime,strike must be equal aaoption id
   * @param commonMsg struct
     * optionId; // aaoption id
     * amount; // order amount ,means total amount
     * tradeType; //LONG SHORT
     * market; // aaoption market address
   */
  function openPosition(
    AAOptionMsg[] memory optionMsg,
    AAMMsg memory aamMsg,
    CommonMsg memory commonMsg
  ) external returns (uint256 totalCost);

  /**
   * @dev close a position, which may be long call, long put, short call or short put.
   * @param optionMsg struct
     *  maker.
     *  amount:aggregator match amount for maker
     *  signAmount : maker sign with amount (signAmount must be ge match amount)
     *  signTime : maker sign with time (signTime must be gt currentTime)
     *  price : maker's price and sign with price
     *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,chainId)
   * @param aamMsg struct
     * amount; // aam match amount
     * price; // aam avg price
     * slippage; // aam slippage 10000 means 1,so 10 means 0.001,1 means 0.0001
     * listingId; // aam option id expireTime,strike must be equal aaoption id
   * @param commonMsg struct
     * optionId; // aaoption id
     * amount; // order amount ,means total amount
     * tradeType; //LONG SHORT
     * market; // aaoption market address
   */
  function closePosition(
    AAOptionMsg[] memory optionMsg,
    AAMMsg memory aamMsg,
    CommonMsg memory commonMsg
  ) external returns (uint256 totalCost);

  function settingMarketInfo(RouterMarketInfo memory marketInfo,address market) external;

  function settleOptions(address market, uint256 optionId) external;

  function createRouterId(address _market, uint256 _optionId, uint256 _listingId,uint256 _boardId) external returns(uint256);

  function createRouterIdBatch(address[] memory _markets, uint256[] memory _optionIds, uint256[]  memory _listingIds, uint256[] memory _boardIds) external returns(uint256[] memory);
}

pragma solidity ^0.8.4;

interface IAAMOptionMarket {
  struct OptionListing {
    uint256 id;
    uint256 strike;
    uint256 skew;
    uint256 longCall;
    uint256 shortCall;
    uint256 longPut;
    uint256 shortPut;
    uint256 boardId;
  }

  struct OptionBoard {
    uint256 id;
    uint256 expiry;
    uint256 iv;
    bool frozen;
    uint256[] listingIds;
  }

  enum TradeType {LONG_CALL, SHORT_CALL, LONG_PUT, SHORT_PUT}

  enum Error {
    TransferOwnerToZero,
    InvalidBoardId,
    InvalidBoardIdOrNotFrozen,
    InvalidListingIdOrNotFrozen,
    StrikeSkewLengthMismatch,
    BoardMaxExpiryReached,
    CannotStartNewRoundWhenBoardsExist,
    ZeroAmountOrInvalidTradeType,
    BoardFrozenOrTradingCutoffReached,
    QuoteTransferFailed,
    BaseTransferFailed,
    BoardNotExpired,
    BoardAlreadyLiquidated,
    OnlyOwner,
    Last
  }

  function maxExpiryTimestamp() external view returns (uint256);

  function optionBoards(uint256)
    external
    view
    returns (
      uint256 id,
      uint256 expiry,
      uint256 iv,
      bool frozen
    );

  function optionListings(uint256)
    external
    view
    returns (
      uint256 id,
      uint256 strike,
      uint256 skew,
      uint256 longCall,
      uint256 shortCall,
      uint256 longPut,
      uint256 shortPut,
      uint256 boardId
    );

  function boardToPriceAtExpiry(uint256) external view returns (uint256);

  function listingToBaseReturnedRatio(uint256) external view returns (uint256);

  function transferOwnership(address newOwner) external;

  function setBoardFrozen(uint256 boardId, bool frozen) external;

  function setBoardBaseIv(uint256 boardId, uint256 baseIv) external;

  function setListingSkew(uint256 listingId, uint256 skew) external;

  function createOptionBoard(
    uint256 expiry,
    uint256 baseIV,
    uint256[] memory strikes,
    uint256[] memory skews
  ) external returns (uint256);

  function addListingToBoard(
    uint256 boardId,
    uint256 strike,
    uint256 skew
  ) external;

  function getLiveBoards() external view returns (uint256[] memory _liveBoards);

  function getBoardListings(uint256 boardId) external view returns (uint256[] memory);

  function openPosition(
    uint256 _listingId,
    TradeType tradeType,
    uint256 amount
  ) external returns (uint256 totalCost);

  function closePosition(
    uint256 _listingId,
    TradeType tradeType,
    uint256 amount
  ) external returns (uint256 totalCost);

  function liquidateExpiredBoard(uint256 boardId) external;

  function settleOptions(uint256 listingId, TradeType tradeType) external;
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IAAOptionBase is IERC1155{



    function mint(address account, uint256 id, uint256 amount, bytes memory data)
    external;

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

}

pragma solidity ^0.8.4;

interface ITokenDecimals {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.4;

interface IAABaseData {

    // poolId same optionId
    /**
    * totalLockAmount
    * executeAmount: settled amount
    * spotPrice: settle amount
    */
    struct AAOptionLockPool{
        uint256 poolId;
        uint256 totalLockAmount;
        uint256 executeAmount;
        uint256 spotPrice;
    }

    /**
       *  maker.
       *  amount:aggregator match amount for maker
       *  signAmount : maker sign with amount (signAmount must be ge match amount)
       *  signTime : maker sign with time (signTime must be gt currentTime)
       *  price : maker's price and sign with price
       *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime,makerNonce)
    */
    struct AAOptionMsg{
        address maker;
        uint256 amount;
        uint256 signAmount;
        uint256 signTime;
        uint256 price;
        bytes sign;
    }

    enum TradeType {LONG, SHORT}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}