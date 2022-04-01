// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IAAOption.sol";
import "./interface/IAAOptionMarket.sol";
import "./interface/IAAOptionRouter.sol";
import "./interface/IAAMOptionMarket.sol";
import "./interface/IAAOptionBase.sol";
import "./interface/ITokenDecimals.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract AAOptionRouter is Ownable, IAAOptionRouter ,ERC1155Receiver{

    IAAOptionBase internal routerProof;

    IAAOptionBase internal routerOption;

    // key : AAOptionMarket address
    mapping(address => RouterMarketInfo) public marketInfo;

    // uint256(uint160(AAOptionMarket)) + AAOptionId =>AAM listingId
    mapping(uint256 => uint256) public marketOptionId;

    // address (aam/aao) =》 uint256(uint160(AAOptionMarket)) + AAOptionId =>lockAmount:user lock record
    mapping(address => mapping(uint256 => uint256)) public lockInfo;

    // address (aam/aao) =》 uint256(uint160(AAOptionMarket)) + AAOptionId =>optionAmount:user option record
    mapping(address => mapping(uint256 => uint256)) public optionInfo;

    // uint256(uint160(AAOptionMarket)) + AAOptionId =>SettleInfo
    mapping(uint256 => SettleInfo) public settleInfo;

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
    }

    function createRouterId(address _market, uint256 _optionId,uint256 _listingId) public override onlyOwner() returns(uint256){
        uint256 temp = uint256(uint160(_market)) + _optionId;
        marketOptionId[temp] = _listingId;
        return temp;
    }

    function createRouterIdBatch(address[] memory _markets, uint256[] memory _optionIds,uint256[]  memory _listingIds) public override onlyOwner() returns(uint256[] memory){
        uint256[] memory ids = new uint256[](_markets.length);
        for (uint256 i = 0; i < _markets.length; i++) {
            ids[i] = createRouterId(_markets[i],_optionIds[i],_listingIds[i]);
        }
        return ids;
    }


    function settingMarketInfo(RouterMarketInfo memory _marketInfo,address market) public override onlyOwner(){
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
        uint256 routerOptionId = uint256(uint160(commonMsg.market)) + optionDetail.id;
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
    ) external override returns (uint256 totalCost){
        IAAMOptionMarket.TradeType aamType;
        DealInfoDto memory dealInfoDto = preDealInfo(optionMsg,aamMsg,commonMsg);
        if (commonMsg.tradeType == TradeType.LONG) {
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
            require(marketOptionId[dealInfoDto.routerOptionId] == aamMsg.listingId, "listingId not match");
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
    ) external override returns (uint256 totalCost){
        IAAMOptionMarket.TradeType aamType;
        DealInfoDto memory dealInfoDto = preDealInfo(optionMsg,aamMsg,commonMsg);
        if (commonMsg.tradeType == TradeType.LONG) {
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
            require(marketOptionId[dealInfoDto.routerOptionId] == aamMsg.listingId, "listingId not match");
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
    }

    function _settleAAM(address _option, address _market, uint256 _listingId, IAAMOptionMarket.TradeType _type) internal {
        uint256 amount = IERC1155(_option).balanceOf(address(this), _listingId + uint256(_type));
        if(amount > 0){
            IAAMOptionMarket(_market).settleOptions(_listingId,_type);
        }
    }

    function _settleRouter(address _market, uint256 _optionId) internal {
        uint256 routerOptionId = uint256(uint160(_market)) + _optionId;
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
        if(marketOptionId[routerOptionId] > 0){
            if(optionDetail.optionType){
                settleInfo[routerOptionId].profit += (afterAAOQuoteBalance - beforeQuoteBalance);
                settleInfo[routerOptionId].unlockAmount += (afterAAOBaseBalance - beforeBaseBalance);
                _settleAAM(tempMarketInfo.aamOption, tempMarketInfo.aamMarket, marketOptionId[routerOptionId], IAAMOptionMarket.TradeType.LONG_CALL);
                settleInfo[routerOptionId].profit += (IERC20(tempMarketInfo.quoteAsset).balanceOf(address(this)) - afterAAOQuoteBalance);
                _settleAAM(tempMarketInfo.aamOption, tempMarketInfo.aamMarket, marketOptionId[routerOptionId], IAAMOptionMarket.TradeType.SHORT_CALL);
                settleInfo[routerOptionId].unlockAmount += (IERC20(tempMarketInfo.baseAsset).balanceOf(address(this)) - afterAAOBaseBalance);
            }else{
                settleInfo[routerOptionId].profit += (afterAAOQuoteBalance-beforeQuoteBalance-amount);
                settleInfo[routerOptionId].unlockAmount += amount;
                _settleAAM(tempMarketInfo.aamOption, tempMarketInfo.aamMarket, marketOptionId[routerOptionId], IAAMOptionMarket.TradeType.LONG_PUT);
                uint256 afterLongPutBalance = IERC20(tempMarketInfo.quoteAsset).balanceOf(address(this));
                settleInfo[routerOptionId].profit += ( afterLongPutBalance - afterAAOQuoteBalance);
                _settleAAM(tempMarketInfo.aamOption, tempMarketInfo.aamMarket, marketOptionId[routerOptionId], IAAMOptionMarket.TradeType.SHORT_PUT);
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
        uint256 routerOptionId = uint256(uint160(market)) + optionId;
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

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

  function checkSign(AAOptionMsg memory optionMsg, uint256 optionId, TradeType tradeType) external view;
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

  function createRouterId(address _market, uint256 _optionId, uint256 _listingId) external returns(uint256);

  function createRouterIdBatch(address[] memory _markets, uint256[] memory _optionIds, uint256[]  memory _listingIds) external returns(uint256[] memory);
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
       *  sign: sign(address(this),optionId,price,amount,tradeType,expireTime)
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