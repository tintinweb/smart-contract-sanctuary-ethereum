/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: NONE

/** This file's constructs, patterns, and usages are proprietary.
    No licenses are granted for any use without the
    written permission of Todd Andrew Durica (@MooncoHodlings).
    Any unlicensed use will be followed up by a law suit.
*/
//  ███████╗██████╗  ██████╗  ██████╗ ███████╗██╗  ██╗
//  ██╔════╝██╔══██╗██╔═══██╗██╔════╝ ██╔════╝╚██╗██╔╝
//  █████╗  ██████╔╝██║   ██║██║  ███╗█████╗   ╚███╔╝
//  ██╔══╝  ██╔══██╗██║   ██║██║   ██║██╔══╝   ██╔██╗
//  ██║     ██║  ██║╚██████╔╝╚██████╔╝███████╗██╔╝ ██╗
//  ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝
//    A (far) more efficient ETH Reflection ERC20!
//              Save our rainforests,
//                our biodiversity!
//                Froge revolution.

pragma solidity 0.8.10;

interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
}
interface IERC20 {
  function balanceOf(address owner) external view returns (uint);
}
interface IUniV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);
  function nonces(address owner) external view returns (uint);
  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(address indexed sender,uint amount0In,uint amount1In,uint amount0Out,uint amount1Out,address indexed to);
  event Sync(uint112 reserve0, uint112 reserve1);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function initialize(address, address) external;
}
interface IUniV2Router {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
  function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
  /*END 01, BEGIN 02*/
  function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IFrogeX {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event HopEvt(uint256 indexed fxOut,uint256 indexed weiIn);
  event LqtyEvt(uint256 indexed fxOut,uint256 indexed weiOut);
  event MktgEvt(uint256 indexed weiOut);
  event ChtyEvt(uint256 indexed weiOut);
  event SetFees(
    uint16 indexed _ttlFeePctBuys,
    uint16 indexed _ttlFeePctSells,
    uint8 _ethPtnChty,
    uint8 _ethPtnMktg,
    uint8 _tknPtnLqty,
    uint8 _ethPtnLqty,
    uint8 _ethPtnRwds
  );
  event ExcludeFromFees(address indexed account);
  event ExcludeFromRewards(address indexed account);
  event SetBlacklist(address indexed account, bool indexed toggle);
  event SetLockerUnlockDate(uint32 indexed oldUnlockDate,uint32 indexed newUnlockDate);
  event SetMinClaimableDivs(uint64 indexed newMinClaimableDivs);
  event LockerExternalAddLiquidityETH(uint256 indexed fxTokenAmount);
  event LockerExternalRemoveLiquidityETH(uint256 indexed lpTokenAmount);
  event XClaim(address indexed user, uint256 indexed amount);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint72);
  function xTotalSupply() external view returns (uint72);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner_, address spender_) external view returns (uint256);
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
  function getUniV2Pair() external view returns (address);
  function getUniV2Router() external view returns (address);
  function getFXSwap() external view returns (address);
  function getConfig() external view returns (
    uint64 _hopThreshold, uint64 _lqtyThreshold, uint32 _lockerUnlockDate,
    uint16 _xGasForClaim, uint64 _xMinClaimableDivs, bool   _tradingEnabled,
    uint16 _ttlFeePctBuys, uint16 _ttlFeePctSells,
    uint16 _ethPtnChty, uint16 _ethPtnMktg, uint16 _tknPtnLqty,
    uint16 _ethPtnLqty, uint16 _ethPtnRwds
  );
  function getAccount(address account) external view returns (
    uint256 _balance, uint256 _xDivsAvailable, uint256 _xDivsEarnedToDate, uint256 _xDivsWithdrawnToDate,
    bool _isAMMPair, bool _isBlackListedBot, bool _isExcludedFromRwds, bool _isExcludedFromFees
  );
  function xGetDivsAvailable(address acct) external view returns (uint256);
  function xGetDivsEarnedToDate(address acct) external view returns (uint256);
  function xGetDivsWithdrawnToDate(address account) external view returns (uint88);
  function xGetDivsGlobalTotalDist() external view returns (uint88);
  function withdrawCharityFunds(address payable charityBeneficiary) external;
  function withdrawMarketingFunds(address payable marketingBeneficiary) external;
  function lockerAdvanceLock(uint32 nSeconds) external;
  function lockerExternalAddLiquidityETH(uint256 fxTokenAmount) external payable;
  function lockerExternalRemoveLiquidityETH(uint256 lpTokenAmount) external;
  function activate() external;
  function setHopThreshold(uint64 tokenAmt) external;
  function setLqtyThreshold(uint64 weiAmt) external;
  function setAutomatedMarketMakerPair(address pairAddr, bool toggle) external;
  function excludeFromFees(address account) external;
  function excludeFromRewards(address account) external;
  function setBlackList(address account, bool toggle) external;
  function setGasForClaim(uint16 newGasForClaim) external;
  function burnOwnerTokens(uint256 amount) external;
  function renounceOwnership() external;
  function transferOwnership(address newOwner) external;
  function xClaim() external;
  function fxAddAirdrop (
    address[] calldata accts, uint256[] calldata addAmts,
    uint256 tsIncrease, uint256 xtsIncrease
  ) external;
  function fxSubAirdrop (
    address[] calldata accts, uint256[] calldata subAmts,
    uint256 tsDecrease, uint256 xtsDecrease
  ) external;
}
//interface IFXSwap {
//  function swapExactTokensForETHSFOTT(uint amountIn) external;
//  function lockerExternalRemoveLiquidityETHReceiver(uint256 lpTokenAmount, address _owner) external;
//}
contract FXSwap {
  IFrogeX private FX;
  IUniV2Router private UniV2Router;
  IUniV2Pair private UniV2Pair;
  IWETH private WETH;
  bool immutable private orderIsFxWeth;//always sort to FX,WETH
  modifier onlyFX(){require(msg.sender == address(FX), "FXSwap: caller must be FX"); _;}
  constructor(address _FX,address _UniV2Router,address _UniV2Pair,address _WETH){
    FX = IFrogeX(_FX);
    UniV2Router = IUniV2Router(_UniV2Router);
    UniV2Pair = IUniV2Pair(_UniV2Pair);
    WETH = IWETH(_WETH);
    orderIsFxWeth = _FX<_WETH?true:false;
  }
  receive() external payable {
    require(msg.sender == address(WETH), "FXSwap only accepts WETHs ETH");
  }

  // fetches and sorts the reserves for a pair
  function getReserves() private view returns (uint reserveA, uint reserveB) {
    (reserveA, reserveB,) = UniV2Pair.getReserves();
    if(!orderIsFxWeth){(reserveA, reserveB)=(reserveB, reserveA);}
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) private pure returns (uint amountOut) {
    require(amountIn > 0, "FXSwap: INSUFFICIENT_INPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "FXSwap: INSUFFICIENT_LIQUIDITY");
    uint amountInWithFee = (amountIn * 997);
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = (reserveIn * 1000) + amountInWithFee;
    amountOut = numerator / denominator;
  }

  function swapExactTokensForETHSFOTT() external onlyFX returns(uint amountOut){
    (uint reserveInput, uint reserveOutput) = getReserves();
    uint amountInput = FX.balanceOf(address(UniV2Pair)) - reserveInput;
    uint amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
    UniV2Pair.swap(uint(0), amountOutput, address(this), new bytes(0));
    amountOut = IERC20(address(WETH)).balanceOf(address(this));
    WETH.withdraw(amountOut);
    require(address(this).balance >= amountOut, "FXSwap:sendValue: insuff.bal");
    (bool success,) = address(FX).call{value:amountOut}("");
    require(success, "FXSwap:ETH_TRANSFER_FAILED");
  }

  function lockerExternalRemoveLiquidityETHReceiver(uint256 lpTokenAmount, address _owner) external onlyFX {
    require(UniV2Pair.balanceOf(address(FX)) >= lpTokenAmount, "FXSwap: insuff. lpt bal");
    UniV2Pair.transferFrom(address(FX),address(UniV2Pair), lpTokenAmount);
    //pair.burn() here sends both tokens to this contract (contrast nonETH direct to caller)
    (uint amt0, uint amt1) = UniV2Pair.burn(address(this));
    (uint amtFX, uint amtETH) = address(this) < address(WETH) ? (amt0, amt1) : (amt1, amt0);
    require(FX.balanceOf(address(this)) >= amtFX, "FXSwap: insuff. frogex tokens");
    FX.transfer(_owner,  amtFX);
    WETH.withdraw(amtETH);
    require(address(this).balance >= amtETH, "FXSwap:sendValue: insuff.bal");
    (bool success,) = _owner.call{value:amtETH}("");
    require(success, "FXSwap:ETH_TRANSFER_FAILED");
  }

}


/*
  2**8     0:               256.0
  2**16    0:            65_536.0  (65.5k)
  2**24    0:        16_777_216.0  (16.7mn)
  2**32    0:     4_294_967_296.0  (4.2bn)

  2**32   -9:                 4.294967296
  2**32  -18:                 0.000000004294967296
  2**48   -9:           281_474.976710656
  2**48  -18:                 0.000281474976710656
  2**56   -9:        72_057_594.037927936
  2**56  -18:                 0.072057594037927936
  2**64   -9:    18_446_744_073.709551616         (18.4bn)
  2**64  -18:                18.446744073709551616
  2**72   -9: 4_722_366_482_869.645213696         (4.7tr)
          338824521750836606685 000000000
  2**72  -18:             4_722.366482869645213696

  2**80   -9:                   1_208_925_819_614_629.174706176           (1.2 quadrillion)
  2**80  -18:                               1_208_925.819614629174706176
  2**88   -9:                 309_485_009_821_345_068.724781056           (309 quadrillion)
  2**88  -18:                             309_485_009.821345068724781056  (309.4mn)
  2**96   -9:              79_228_162_514_264_337_593.543950336           (79.2 quintillion)
  2**96  -18:                          79_228_162_514.264337593543950336  (79.2bn)
  2**128  -9: 340_282_366_920_938_463_463_374_607_431.768211456           (some crazy number)
  2**128 -18:             340_282_366_920_938_463_463.374607431768211456  (340 quintillion)
  2**256 115792089237316195423570985008687907853269984665640564039457584007913129639935
*/

contract FrogeX is IFrogeX {
  struct AcctInfo {
    uint128 _balance;
    uint88 xDivsWithdrawnToDate;
    bool isAMMPair;
    bool isBlackListedBot;
    bool isExcludedFromRwds;
    bool isExcludedFromFees;//also exempts max sell limit
    //^^ 248
  }
  struct Config {
    uint64 hopThreshold;
    uint64 lqtyThreshold;
    uint32 lockerUnlockDate;
    uint16 xGasForClaim;//65536 max
    uint64 xMinClaimableDivs;//18.4 ETH max setting
    bool tradingEnabled;// u8
    //^^ 248

    uint16 ttlFeePctBuys;  // 500
    uint16 ttlFeePctSells; // 800
    uint8 ethPtnChty;    // 200
    uint8 ethPtnMktg;    // 100
    uint8 tknPtnLqty; // 40
    uint8 ethPtnLqty;    // 100
    uint8 ethPtnRwds;    // 400
    //^^ 112
  }
  uint256 private xDivsPerShare;

  uint72 private _totalSupply;//must be 72+
  uint72 private _xTotalSupply;//must be 72+
  uint88 private xDivsGlobalTotalDist;//needs 80 or higher
  uint8 private constant _FALSE = 1;
  uint8 private constant _TRUE = 2;
  uint8 private sellEvtEntrancy;
  //^^ 256

  uint136 private constant xMagnitude = 2**128;
  uint48 private constant xMinForDivs = 100000 * (10**9);//100k fx, u48~281_474 max
  uint72 private pond_HOPPING_POWER;
  //^^ 256

  uint72 private pond_ES_CHTY_LILY;
  uint72 private pond_ES_MKTG_LILY;
  uint72 private pond_ES_LQTY_LILY;//can be 64 if certain never over 18.4eth
  //^^ 216

  uint64 private pond_TS_LQTY_LILY;
  address private _owner;
  //^^ 224

  IUniV2Router private UniV2Router;
  IUniV2Pair private UniV2Pair;
  IWETH private WETH;
  FXSwap private FxSwap;

  Config private config;

  mapping(address=>AcctInfo) private _a;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => int256) private xDivsCorrections;

  modifier onlyOwner(){require(_owner == msg.sender,"onlyOwner"); _;}

  constructor (address routerAddress, uint72 initLqtyAmt) {
    _transferOwnership(msg.sender);
    sellEvtEntrancy = _FALSE;
    unchecked{config.hopThreshold = 100_000_000 * (10**9);}//100mn fx
    unchecked{config.lqtyThreshold = 25 * (10**16);}//.25 eth
    //to be advanced upon successful launch
    config.lockerUnlockDate = uint32(block.timestamp);
    config.xGasForClaim = 3000;
    config.xMinClaimableDivs = 600_000_000_000_000;//about 5.5 USD at time of deployment
    config.ttlFeePctBuys  =  500;
    config.ttlFeePctSells = 800;

    config.ethPtnChty     = 20;
    config.ethPtnMktg     = 10;
    config.tknPtnLqty     = 6;
    config.ethPtnLqty     = 9;
    config.ethPtnRwds     = 40;

    IUniV2Router _uniswapV2Router = IUniV2Router(routerAddress);
    UniV2Router = _uniswapV2Router;
    address wethAddr = _uniswapV2Router.WETH();
    WETH = IWETH(wethAddr);

    // Create uniswap pair
    address pairAddr = IUniV2Factory(_uniswapV2Router.factory()).createPair(address(this), wethAddr);
    UniV2Pair = IUniV2Pair(pairAddr);
    _a[pairAddr].isAMMPair = true;

    FxSwap = new FXSwap(address(this),routerAddress,pairAddr,wethAddr);

    // exclude from receiving dividends
    _a[pairAddr].isExcludedFromRwds = true;
    _a[address(this)].isExcludedFromRwds = true;
    _a[address(FxSwap)].isExcludedFromRwds = true;
    _a[address(_uniswapV2Router)].isExcludedFromRwds = true;
    _a[address(0x000000000000000000000000000000000000dEaD)].isExcludedFromRwds = true;
    _a[address(0)].isExcludedFromRwds = true;

    // exclude from paying fees or having max transaction amount
    _a[address(this)].isExcludedFromFees = true;
    _a[address(FxSwap)].isExcludedFromFees = true;
    /* _mint for liquidity pool, after which _owner tokens are burned */
    unchecked{_totalSupply += initLqtyAmt;}
    unchecked{_a[_owner]._balance += uint128(initLqtyAmt);}
  }

  function withdrawCharityFunds(address payable charityBeneficiary) external onlyOwner{
    require(charityBeneficiary != address(0), "zero address disallowed");
    emit ChtyEvt(pond_ES_CHTY_LILY);
    (bool success,) = charityBeneficiary.call{value: pond_ES_CHTY_LILY}("");
    require(success, "call to beneficiary failed");
    pond_ES_CHTY_LILY = 0;
  }
  function withdrawMarketingFunds(address payable marketingBeneficiary) external onlyOwner{
    require(marketingBeneficiary != address(0), "zero address disallowed");
    emit MktgEvt(pond_ES_MKTG_LILY);
    (bool success,) = marketingBeneficiary.call{value: pond_ES_MKTG_LILY}("");
    require(success, "call to beneficiary failed");
    pond_ES_MKTG_LILY = 0;
  }

  function _transfer(address from, address to, uint256 amount) internal {
    require(_a[from]._balance >= amount, "insuff. balance for transfer");

    Config memory c = config;
    require(amount > 0,"amount must be above zero");
    require(from != address(0),"from cannot be zero address");
    require(to != address(0),"to cannot be zero address");
    require(!_a[to].isBlackListedBot, "nobots");
    require(!_a[msg.sender].isBlackListedBot, "nobots");
    require(!_a[from].isBlackListedBot, "nobots");

    // 0:buys, 1: sells, 2: xfers
    uint txType = _a[from].isAMMPair ? 0 : _a[to].isAMMPair ? 1 : 2;

    //hardstop check
    require(c.tradingEnabled || msg.sender == _owner, "tradingEnabled hardstop");

    // HOP / ADDLIQUIDITY
    if(txType==1 && sellEvtEntrancy != _TRUE){
      sellEvtEntrancy = _TRUE;
      if(pond_ES_LQTY_LILY >= c.lqtyThreshold){
        uint _pond_TS_LQTY = pond_TS_LQTY_LILY;
        uint _pond_ES_LQTY = pond_ES_LQTY_LILY;
        if(_pond_TS_LQTY == 0){
          pond_ES_MKTG_LILY += uint72(_pond_ES_LQTY);
          pond_ES_LQTY_LILY = 0;
        }else{
          lockerInternalAddLiquidityETHBlind(_pond_TS_LQTY,_pond_ES_LQTY);
          pond_TS_LQTY_LILY = 0;
          pond_ES_LQTY_LILY = 0;
          emit LqtyEvt(_pond_TS_LQTY, _pond_ES_LQTY);
        }
      }
      // FROGE HOP EVENT
      else {
        uint HOPPING_POWER = pond_HOPPING_POWER;
        if (HOPPING_POWER >= c.hopThreshold) {
          uint _ethPtnTotal;
          uint _ovlPtnTotal;
        unchecked{_ethPtnTotal = c.ethPtnChty + c.ethPtnMktg + c.ethPtnLqty + c.ethPtnRwds;}
        unchecked{_ovlPtnTotal = _ethPtnTotal + c.tknPtnLqty;}
          /* Set aside some tokens for liquidity.*/
          uint magLqTknPct = (uint(c.tknPtnLqty) * 10000) / _ovlPtnTotal;
          uint lqtyTokenAside = (HOPPING_POWER * magLqTknPct) / 10000;
          pond_TS_LQTY_LILY += uint64(lqtyTokenAside);

          // contract itself sells its tokens and recieves ETH,
          _transferSuper(address(this), address(UniV2Pair), (HOPPING_POWER - lqtyTokenAside));
          uint createdEth = FxSwap.swapExactTokensForETHSFOTT();
          emit HopEvt(HOPPING_POWER, createdEth);

          uint pond_ES_CHTY = (createdEth * c.ethPtnChty) / _ethPtnTotal;
          uint pond_ES_MKTG = (createdEth * c.ethPtnMktg) / _ethPtnTotal;
          uint pond_ES_LQTY = (createdEth * c.ethPtnLqty) / _ethPtnTotal;
          uint pond_ES_RWDS = createdEth - pond_ES_CHTY - pond_ES_MKTG - pond_ES_LQTY;

          //rewards has no LILY - we assign the ETH immediately
          xDivsPerShare += ((pond_ES_RWDS * xMagnitude) / _xTotalSupply);
          xDivsGlobalTotalDist += uint88(pond_ES_RWDS);

          pond_ES_CHTY_LILY += uint72(pond_ES_CHTY);
          pond_ES_MKTG_LILY += uint72(pond_ES_MKTG);
          pond_ES_LQTY_LILY += uint72(pond_ES_LQTY);

          pond_HOPPING_POWER = 0;
        }
      }
      // END: FROGE HOP EVENT
      sellEvtEntrancy = _FALSE;
    }
    // SEND

    /* fees are collected as tokens held by the contract until a threshold is met.
       fees are only split into portions during the liquidation*/
    if (txType!=2//no fees on simple transfers
    && !_a[from].isExcludedFromFees
    && !_a[to].isExcludedFromFees) {
      uint feePct = txType==0 ? c.ttlFeePctBuys : c.ttlFeePctSells;
      uint feesAmount = (amount * feePct)/10000;
      amount -= feesAmount;
      pond_HOPPING_POWER += uint72(feesAmount);
      //xTotalSupply may or may not be adjusted here
      // depending on rewards eligibility for "from" address
      //No xmint - contract is always excluded from rewards
      xBurn(from, feesAmount);
      //give our contract some tokens as a fee
      _transferSuper(from, address(this), feesAmount);
    }

    //perform the intended transfer, where amount may or may not have been modified via applyFees
    xBurn(from, amount);
    xMint(to, amount);
    _transferSuper(from, to, amount);

    xProcessAccount(payable(from));
    xProcessAccount(payable(to));
  }
  /* END transfer() */

  /* BEGIN LOCKER & LIQUIDITY OPS  */
  function lockerAdvanceLock(uint32 nSeconds) external onlyOwner {
    //Maximum setting: 4294967296 (February 7, 2106 6:28:16 AM)
    uint32 oldUnlockDate = config.lockerUnlockDate;
    uint32 newUnlockDate = oldUnlockDate + nSeconds;
    config.lockerUnlockDate = newUnlockDate;
    emit SetLockerUnlockDate(oldUnlockDate, newUnlockDate);
  }
  function lockerExternalAddLiquidityETH(uint256 fxTokenAmount) external payable onlyOwner{
    require(fxTokenAmount>0 && msg.value>0,"must supply both fx and eth");
    _transferSuper(_owner, address(this), fxTokenAmount);
    lockerInternalAddLiquidityETHOptimal(fxTokenAmount,msg.value);
    emit LockerExternalAddLiquidityETH(fxTokenAmount);
  }
  function lockerExternalRemoveLiquidityETH(uint256 lpTokenAmount) external onlyOwner {
    require(config.lockerUnlockDate < block.timestamp,"unlockDate not yet reached");
    require(UniV2Pair.balanceOf(address(this)) >= lpTokenAmount,"not enough lpt held by contract");
    // address(this) approves FxSwap to transit to the pair contract
    //  the specified PairToken Amount it currently holds
    UniV2Pair.approve(address(FxSwap), lpTokenAmount /*~uint256(0)*/);
    FxSwap.lockerExternalRemoveLiquidityETHReceiver(lpTokenAmount, _owner);
    emit LockerExternalRemoveLiquidityETH(lpTokenAmount);
  }

  function lockerInternalAddLiquidityETHOptimal(uint256 fxTokenAmount,uint256 weiAmount) private{
    address addrWETH = address(WETH);
    address addrFlowx = address(this);
    (uint rsvFX, uint rsvETH,) = UniV2Pair.getReserves();
    if(addrFlowx>addrWETH){(rsvFX,rsvETH)=(rsvETH,rsvFX);}
    uint amountA;
    uint amountB;
    if (rsvFX == 0 && rsvETH == 0) {
      (amountA, amountB) = (fxTokenAmount, weiAmount);
    } else {
      uint amountADesired = fxTokenAmount;
      uint amountBDesired = weiAmount;
      uint amountBOptimal = (amountADesired * rsvETH) / rsvFX;//require(amountA > 0)
      if (amountBOptimal <= amountBDesired) {
        (amountA, amountB) = (amountADesired, amountBOptimal);
      }
      else {
        uint amountAOptimal = (amountBDesired * rsvFX) / rsvETH;//require(amountA > 0)
        require(amountAOptimal <= amountADesired, "optimal liquidity calc failed");
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
    lockerInternalAddLiquidityETHBlind(amountA, amountB);
  }
  function lockerInternalAddLiquidityETHBlind(uint256 fxTokenAmount,uint256 weiAmount) private{
    address addrPair = address(UniV2Pair);
    address addrFlowx = address(this);
    _transferSuper(addrFlowx,addrPair,fxTokenAmount);
    WETH.deposit{value: weiAmount}();
    require(WETH.transfer(addrPair, weiAmount), "failed WETH xfer to lp contract");//(address to, uint value)
    UniV2Pair.mint(addrFlowx);
  }

  /* END LOCKER & LIQUIDITY OPS */

  /* BEGIN FX GENERAL CONTROLS */
  function activate() external onlyOwner {
    config.tradingEnabled = true;}
  function setHopThreshold(uint64 tokenAmt) external onlyOwner {
    require(tokenAmt>=(10 * (10**9)), "out of accepted range");
    require(tokenAmt<=(2_000_000_000 * (10**9)), "out of accepted range");
    config.hopThreshold = tokenAmt;
  }
  function setLqtyThreshold(uint64 weiAmt) external onlyOwner {
    require(weiAmt>=100, "out of accepted range");
    config.lqtyThreshold = weiAmt;
  }
  function setFees (uint16 _ttlFeePctBuys, uint16 _ttlFeePctSells,
    uint8 _ethPtnChty, uint8 _ethPtnMktg, uint8 _tknPtnLqty, uint8 _ethPtnLqty, uint8 _ethPtnRwds
  ) external onlyOwner {
    require(
      _ttlFeePctBuys>=10 && _ttlFeePctBuys<=1000
      && _ttlFeePctSells>=10 && _ttlFeePctSells<=1600,
      "Fee pcts out of accepted range"
    );
    require(
      ((_tknPtnLqty>0 && _ethPtnLqty>0)||(_tknPtnLqty==0 && _ethPtnLqty==0))
      && _ethPtnChty<=100
      && _ethPtnMktg<=100
      && _tknPtnLqty<=100
      && _ethPtnLqty<=100
      && _ethPtnRwds<=100,
      "Portions outside accepted range"
    );
    config.ttlFeePctBuys  = _ttlFeePctBuys;
    config.ttlFeePctSells = _ttlFeePctSells;
    config.ethPtnChty = _ethPtnChty;
    config.ethPtnMktg = _ethPtnMktg;
    config.tknPtnLqty = _tknPtnLqty;
    config.ethPtnLqty = _ethPtnLqty;
    config.ethPtnRwds = _ethPtnRwds;
    emit SetFees(_ttlFeePctBuys, _ttlFeePctSells, _ethPtnChty, _ethPtnMktg, _tknPtnLqty, _ethPtnLqty, _ethPtnRwds);
  }
  function setAutomatedMarketMakerPair(address pairAddr, bool toggle) external onlyOwner {
    require(pairAddr != address(UniV2Pair),"original pair is constant");
    require(_a[pairAddr].isAMMPair != toggle,"setting already exists");
    _a[pairAddr].isAMMPair = toggle;
    if(toggle && !_a[pairAddr].isExcludedFromRwds){
      _excludeFromRewards(pairAddr);
    }
  }
  function excludeFromFees(address account) external onlyOwner {
    require(!_a[account].isExcludedFromFees,"already excluded");
    _a[account].isExcludedFromFees = true;
    emit ExcludeFromFees(account);
  }
  function excludeFromRewards(address account) external onlyOwner {
    _excludeFromRewards(account);
  }
  function _excludeFromRewards(address account) private onlyOwner {
    //irreversibly and completely removes from rewards mechanism
    require(!_a[account].isExcludedFromRwds,"already excluded");
    _a[account].isExcludedFromRwds = true;
    xProcessAccount(payable(account));
    if(_a[account]._balance>xMinForDivs){
      _xTotalSupply -= uint72(_a[account]._balance);
      delete xDivsCorrections[account];
    }
    emit ExcludeFromRewards(account);
  }
  function setBlackList(address account, bool toggle) external onlyOwner {
    if(toggle) {
      require(account != address(UniV2Router)
      && account != address(UniV2Pair)
      && account != address(FxSwap)
      && account != address(_owner)
      ,"ineligible for blacklist");
      _a[account].isBlackListedBot = true;
    }else{_a[account].isBlackListedBot = false;}
    emit SetBlacklist(account, toggle);
  }
  function setGasForClaim(uint16 newGasForClaim) external onlyOwner {
    require(newGasForClaim>3000,"not enough gasForClaim");
    config.xGasForClaim = uint16(newGasForClaim);
  }
  function setMinClaimableDivs(uint64 newMinClaimableDivs) external onlyOwner {
    require(newMinClaimableDivs>0,"out of accepted range");
    config.xMinClaimableDivs = newMinClaimableDivs;
    emit SetMinClaimableDivs(newMinClaimableDivs);
  }
  function getConfig() external view returns (
    uint64 _hopThreshold, uint64 _lqtyThreshold, uint32 _lockerUnlockDate,
    uint16 _xGasForClaim, uint64 _xMinClaimableDivs, bool   _tradingEnabled,
    uint16 _ttlFeePctBuys, uint16 _ttlFeePctSells,
    uint16 _ethPtnChty, uint16 _ethPtnMktg, uint16 _tknPtnLqty,
    uint16 _ethPtnLqty, uint16 _ethPtnRwds
  ) {
    Config memory c = config;
    _hopThreshold = c.hopThreshold;
    _lqtyThreshold = c.lqtyThreshold;
    _lockerUnlockDate = c.lockerUnlockDate;
    _xGasForClaim = c.xGasForClaim;
    _xMinClaimableDivs = c.xMinClaimableDivs;
    _tradingEnabled = c.tradingEnabled;
    _ttlFeePctBuys = c.ttlFeePctBuys;
    _ttlFeePctSells = c.ttlFeePctSells;
    _ethPtnChty = c.ethPtnChty;
    _ethPtnMktg = c.ethPtnMktg;
    _tknPtnLqty = c.tknPtnLqty;
    _ethPtnLqty = c.ethPtnLqty;
    _ethPtnRwds = c.ethPtnRwds;
  }
  function getAccount(address account) external view returns (
    uint256 _balance, uint256 _xDivsAvailable, uint256 _xDivsEarnedToDate, uint256 _xDivsWithdrawnToDate,
    bool _isAMMPair, bool _isBlackListedBot, bool _isExcludedFromRwds, bool _isExcludedFromFees
  ){
    _balance = _a[account]._balance;
    _xDivsAvailable = xDivsAvailable(account);
    _xDivsEarnedToDate = xDivsEarnedToDate(account);
    _xDivsWithdrawnToDate = _a[account].xDivsWithdrawnToDate;
    _isAMMPair = _a[account].isAMMPair;
    _isBlackListedBot = _a[account].isBlackListedBot;
    _isExcludedFromRwds = _a[account].isExcludedFromRwds;
    _isExcludedFromFees = _a[account].isExcludedFromFees;
  }
  function xGetDivsAvailable(address acct) external view returns (uint256){
    return xDivsAvailable(acct);
  }
  function xGetDivsEarnedToDate(address acct) external view returns (uint256){
    return xDivsEarnedToDate(acct);
  }
  function xGetDivsWithdrawnToDate(address account) external view returns (uint88){
    return _a[account].xDivsWithdrawnToDate;
  }
  function xGetDivsGlobalTotalDist() external view returns (uint88){
    return xDivsGlobalTotalDist;
  }
  function getUniV2Pair() external view returns (address){return address(UniV2Pair);}
  function getUniV2Router() external view returns (address){return address(UniV2Router);}
  function getFXSwap() external view returns (address){return address(FxSwap);}

  function burnOwnerTokens(uint256 amount) external onlyOwner {
    _burn(msg.sender, amount);
  }
  /*********BEGIN ERC20**********/
  function name() external pure returns (string memory) {return "FrogeX";}
  function symbol() external pure returns (string memory) {return "FROGEX";}
  function decimals() external pure returns (uint8) {return 9;}
  function owner() external view returns (address) {return _owner;}
  function totalSupply() external view returns (uint72) {return _totalSupply;}
  function xTotalSupply() external view returns (uint72) {return _xTotalSupply;}
  function balanceOf(address account) external view returns (uint256) {
    return uint256(_a[account]._balance);
  }
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(msg.sender, recipient, amount); return true;
  }
  function allowance(address owner_, address spender_) external view returns (uint256) {
    return _allowances[owner_][spender_];
  }
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount); return true;
  }
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    uint256 currentAllowance = _allowances[sender][msg.sender];
    require(currentAllowance >= amount, "amount exceeds allowance");
  unchecked {
    _approve(sender, msg.sender, currentAllowance - amount);
  }
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    uint256 currentAllowance = _allowances[msg.sender][spender];
    require(currentAllowance >= subtractedValue, "decreased allowance below zero");
  unchecked {
    _approve(msg.sender, spender, currentAllowance - subtractedValue);
  }
    return true;
  }
  function _transferSuper(address sender, address recipient, uint256 amount) private {
    require(sender != address(0), "transfer from the zero address");
    require(recipient != address(0), "transfer to the zero address");
    uint256 senderBalance = _a[sender]._balance;
    require(senderBalance >= amount, "transfer amount exceeds balance");
  unchecked {
    _a[sender]._balance = uint128(senderBalance - amount);
  }
    _a[recipient]._balance += uint128(amount);
    emit Transfer(sender, recipient, amount);
  }
  function _burn(address account, uint256 amount) private {
    require(account != address(0), "burn from the zero address");
    uint256 accountBalance = _a[account]._balance;
    require(accountBalance >= amount, "burn amount exceeds balance");
  unchecked {
    _a[account]._balance = uint128(accountBalance - amount);
  }
    _totalSupply -= uint72(amount);
    emit Transfer(account, address(0), amount);
  }
  function _approve(address owner_, address spender_, uint256 amount) private {
    require(owner_ != address(0), "approve from zero address");
    require(spender_ != address(0), "approve to zero address");
    _allowances[owner_][spender_] = amount;
    emit Approval(owner_, spender_, amount);
  }
  /*********END ERC20**********/

  /*********BEGIN OWNABLE**********/
  function renounceOwnership() external onlyOwner {
    _transferOwnership(address(0));
  }
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "FxOwn: no zero address");
    require(newOwner != address(_owner), "FxOwn: already owner");
    _transferOwnership(newOwner);
  }
  function _transferOwnership(address newOwner) private {
    address oldOwner = _owner;
    _a[newOwner].isExcludedFromRwds = true;
    _a[newOwner].isExcludedFromFees = true;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
  /*********END OWNABLE**********/

  /*********REWARDS FUNCTIONALITY**********/

  receive() external payable {
    require(_xTotalSupply > 0,"X GON GIVE IT TO YA");
    if (msg.value > 0 && msg.sender != address(FxSwap) && msg.sender != address(UniV2Router)) {
      xDivsPerShare = xDivsPerShare + ((msg.value * xMagnitude) / _xTotalSupply);
      xDivsGlobalTotalDist += uint88(msg.value);
    }
  }

  function xDivsAvailable(address acct) private view returns (uint256){
    return xDivsEarnedToDate(acct) - uint256(_a[acct].xDivsWithdrawnToDate);
  }
  function xDivsEarnedToDate(address acct) private view returns (uint256){
    uint256 currShare =
    (_a[acct].isExcludedFromRwds||_a[acct]._balance<xMinForDivs)
        ?0:_a[acct]._balance;
    return uint256(
      int256(xDivsPerShare * currShare) +
      xDivsCorrections[acct]
    ) / xMagnitude;
  }

  //xMint MUST be called BEFORE intended updates to balances
  function xMint(address acct, uint256 mintAmt) private {
    if(!_a[acct].isExcludedFromRwds){
      uint256 acctSrcBal = _a[acct]._balance;
      if((acctSrcBal + mintAmt) > xMinForDivs){
        mintAmt += (acctSrcBal<xMinForDivs)?acctSrcBal:0;
        _xTotalSupply += uint72(mintAmt);
        xDivsCorrections[acct] -= int256(xDivsPerShare * mintAmt);
      }
    }
  }
  //xBurn MUST be called BEFORE intended updates to balances
  function xBurn(address acct, uint256 burnAmt) private {
    if(!_a[acct].isExcludedFromRwds){
      uint256 acctSrcBal = _a[acct]._balance;
      if(acctSrcBal > xMinForDivs){
        uint256 acctDestBal = acctSrcBal - burnAmt;
        burnAmt += (acctDestBal<xMinForDivs)?acctDestBal:0;
        _xTotalSupply -= uint72(burnAmt);
        xDivsCorrections[acct] += int256(xDivsPerShare * burnAmt);
      }
    }
  }

  function xProcessAccount(address payable account) private returns (bool successful){
    uint256 _divsAvailable = xDivsAvailable(account);
    if (_divsAvailable > config.xMinClaimableDivs) {
      _a[account].xDivsWithdrawnToDate = uint88(_a[account].xDivsWithdrawnToDate + _divsAvailable);
      emit XClaim(account, _divsAvailable);
      (bool success,) = account.call{value: _divsAvailable, gas: config.xGasForClaim}("");
      if (success) {
        return true;
      }else{
        _a[account].xDivsWithdrawnToDate = uint88(_a[account].xDivsWithdrawnToDate - _divsAvailable);
        return false;
      }
    }else{return false;}
  }
  function xClaim() external {
    xProcessAccount(payable(msg.sender));
  }

  function fxAddAirdrop (
    address[] calldata accts, uint256[] calldata addAmts,
    uint256 tsIncrease, uint256 xtsIncrease
  ) external {
    require(_owner == msg.sender && !config.tradingEnabled,"onlyOwner and pre-launch");
    for (uint i; i < accts.length; i++) {
      unchecked{_a[accts[i]]._balance += uint128(addAmts[i]);}
    }
    unchecked{_totalSupply += uint72(tsIncrease);}
    unchecked{_xTotalSupply += uint72(xtsIncrease);}
  }
  function fxSubAirdrop (
    address[] calldata accts, uint256[] calldata subAmts,
    uint256 tsDecrease, uint256 xtsDecrease
  ) external {
    require(_owner == msg.sender && !config.tradingEnabled,"onlyOwner and pre-launch");
    for (uint i; i < accts.length; i++) {
      unchecked{_a[accts[i]]._balance -= uint128(subAmts[i]);}
    }
    unchecked{_totalSupply -= uint72(tsDecrease);}
    unchecked{_xTotalSupply -= uint72(xtsDecrease);}
  }

}