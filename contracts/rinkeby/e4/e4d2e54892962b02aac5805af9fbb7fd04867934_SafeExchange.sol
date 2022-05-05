//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Utils.sol";
import "./DexUtils.sol";
import "./CrossChainLocker.sol";

/*
0x01:eth(ETH) 
0x25:cronos(CRO)
0x56:bsc(BNB)
0x137:polygon(MATIC)
0x250:Fantom(FTM)

//------------main net test------------//
crossChainUtility			:BNB(bsc)->BNB(cronos)
	0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c(BNB bsc)
	0x49974c3c99f4e74d08845c31d3f4f16fdc264ebd(anyBNB bsc)
	0xfa9343c3897324496a05fc75abed6bac29f8a40f(BNB cronos)

crossChainToken				:FTM(bsc) -> FTM(Fantom) 
	0xad29abb318791d579433d831ed122afeaf29dcfe(FTM bsc)
	0xd3a33b8222ba7b25a0ea2a6ddcda237c154046af(anyFTM bsc)
	0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83(FTM Fantom)

integrateCrossChainUtility	:BNB(bsc) -> FTM(bsc) -> FTM(Fantom)  
	0xad29abb318791d579433d831ed122afeaf29dcfe(FTM bsc)
	0xd3a33b8222ba7b25a0ea2a6ddcda237c154046af(anyFTM bsc)
	0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83(FTM Fantom)


target: 
	BNB(cronos) -> BNB(bsc) 	: anySwapOut
	BNB(bsc) -> BNB(cronos) 	: anySwapOutNative
	BNB(bsc) -> ETH(eth)		: pancakeSwap + anySwapOutUnderlying
	BNB(bsc) -> MATIC(polygon)	: pancakeSwap + anySwapOutUnderlying
	ETH(eth) -> BUSD(bsc)		: uniSwap + anySwapOutUnderlying
	MATIC(polygon) -> USDT(bsc) : uniSwap + anySwapOutUnderlying

USDT:
	bsc:	0x55d398326f99059fF775485246999027B3197955	
	eth:	0xdAC17F958D2ee523a2206206994597C13D831ec7
	polygon:0xc2132D05D31c914a87C6611C10748AEb04B58e8F
BUSD:
	bsc:	0xe9e7cea3dedca5984780bafc599bd69add087d56	
	eth:	0x4fabb145d64652a948d72533023f6e7a623c7c53
	polygon:

native:
	0x01:
		BUSD:0x4fabb145d64652a948d72533023f6e7a623c7c53 -> 0xe9e7cea3dedca5984780bafc599bd69add087d56(0x56)
			anytoken:0xd13eb71515dc48a8a367d12f844e5737bab415df
			router:0xe95fd76cf16008c12ff3b3a937cb16cd9cc20284
			ABI:anySwapOutUnderlying(anytoken,toAddress,amount,toChainID)
	0x25:
		BNB:0xfa9343c3897324496a05fc75abed6bac29f8a40f
			router:0x639a647fbe20b6c8ac19e48e2de44ea792c62c5c
			interface:anySwapOut(anytoken,toAddress,amount,toChainID)
	0x56:
		MATIC:0xcc42724c6683b7e57334c4e856f4c9965ed682bd -> 0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270(0x137)
			anytoken:0xbf731bfa03e0095a2039e7e4c3b466efb7f3ec4e
			router:0xf9736ec3926703e85c843fc972bd89a7f8e827c0
			ABI:anySwapOutUnderlying(anytoken,toAddress,amount,toChainID)
		BNB:0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c -> 0xfa9343c3897324496a05fc75abed6bac29f8a40f(0x25)
			router:0x92c079d3155c2722dbf7e65017a5baf9cd15561c
			ABI:anySwapOutNative(anytoken,toAddress,toChainID,{value: amount})
STABLEV3:
	0x01:
		ETH:0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2 -> 0x2170ed0880ac9a755fd29b2688956bd959f933f8
			anytoken:0x0615dbba33fe61a31c7ed131bda6655ed76748b1
			router:0xba8da9dcf11b50b03fd5284f164ef5cdef910705
			ABI:anySwapOutNative(anytoken,toAddress,toChainID,{value: amount})
	0x56:
		ETH:0x2170ed0880ac9a755fd29b2688956bd959f933f8 -> 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2(0x01)
			anytoken:0xdebb1d6a2196f2335ad51fbde7ca587205889360
			router:0xd1c5966f9f5ee6881ff6b261bbeda45972b1b5f3
			ABI:anySwapOutUnderlying(anytoken,toAddress,amount,toChainID)
	0x137
		USDT:0xc2132d05d31c914a87c6611c10748aeb04b58e8f -> 0x55d398326f99059ff775485246999027b3197955(0x56)
			anytoken:0xe3eeda11f06a656fcaee19de663e84c7e61d3cac
			router:0x4f3aff3a747fcade12598081e80c6605a8be192f
			ABI:anySwapOutUnderlying(anytoken,toAddress,amount,toChainID)
		MATIC:0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270 -> 0xcc42724c6683b7e57334c4e856f4c9965ed682bd(bsc)
			anytoken:0x21804205c744dd98fbc87898704564d5094bb167
			router:0x2ef4a574b72e1f555185afa8a09c6d1a8ac4025c
			ABI:anySwapOutNative(anytoken,toAddress,toChainID,{value: amount})
			
*/

contract SafeExchange is ReentrancyGuard, Ownable, TokenManagement {
  IUniswapV2Router02 swapRouter;

  // IAnyswapV4Router anySwapRouter;
  //0xf9736ec3926703e85c843fc972bd89a7f8e827c0 BSC    0x56
  //0x639a647fbe20b6c8ac19e48e2de44ea792c62c5c CRONOS 0x25
  uint256 public fee; // 100 = 1%
  uint256 public standardization = 10000;
  address payable public feeWallet;
  //Event
  event CrossChainLog(address token, address from, address to, uint256 amt, uint256 chainId);
  event SwapNative(address tokenAddr, address from, address to, uint256 amt, uint256 feeAmt, uint256 tokenAmt);
  event CreateSafeLocker(address userAddr, address lockerAddr);
  event EmergentWithdraw(address token, uint256 amt, address userAddr);

  mapping(address => CrossChainLocker) public safeLockers;

  CrossChainLocker[] public safeLockersArr;

  modifier lockerExists(address _locker) {
    bool _lockerNotExists = address(safeLockers[msg.sender]) == address(0);
    CrossChainLocker locker;
    if (!_lockerNotExists) {} else {
      locker = new CrossChainLocker(msg.sender, address(this));
      safeLockers[msg.sender] = locker;
      address lockerAdd = address(safeLockers[msg.sender]);
      safeLockersArr.push(locker);
      emit CreateSafeLocker(msg.sender, lockerAdd);
    }
    _;
  }

  constructor(
    address _uniSwapAddr,
    // address _anySwapAddr,
    address _feeWallet
  ) lockerExists(msg.sender) {
    swapRouter = _uniSwapAddr != address(0) ? IUniswapV2Router02(_uniSwapAddr) : IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    // swapRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // BSC Mainnet
    // swapRouter = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // BSC Testnet

    // swapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // ETH Mainnet
    //swapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // ETH Testnet
    //swapRouter = IUniswapV2Router02(0x145863Eb42Cf62847A6Ca784e6416C1682b1b2Ae); //  cronos vvrouter

    // swapRouter = IUniswapV2Router02(_uniSwapAddr);
    // anySwapRouter = IAnyswapV4Router(_anySwapAddr);
    feeWallet = payable(_feeWallet);
    fee = 50;

    // init add anyTokenList//
    // //bsc//
    // 000000000000000000
    //isPassed = false;
    //addToken(25, 0xEDF0c420bc3b92B961C6eC411cc810CA81F5F21a, 12000000000000000000, 20000000000000000000000000); // USDT -> chain25 (0.02 , 11000 )
    //addToken(1, 0xDebB1d6a2196F2335aD51FBdE7Ca587205889360, 20000000000000000, 9640000000000000000000); // ETH(02 , 9640 )
    //addToken(137, 0xBF731BFa03E0095A2039E7E4C3B466eFB7F3Ec4E, 5000000000000000000, 2500000000000000000000000); // MATIC(5 , 2500000 )
    // //eth//
    //addToken(56, 0x22648C12acD87912EA1710357B1302c6a4154Ebc, 12000000, 20000000000000); // USDT -> chain56 (,105000000)
    // //polygon//
    //addToken(56, 0xE3eeDa11f06a656FcAee19de663E84C7e61d3Cac, 12000000, 20000000000000); // USDT-> chain56(12, 20000000))
    // //cronos//
    //addToken(56, 0x739ca6D71365a08f584c8FC4e1029045Fa8ABC4B, 12000000, 20000000000000); //  USDT-> chain56( 0.02, 11000))
  }

  receive() external payable {}

  //native(source chain) ->wrap(destination chain)
  //BNB(bsc) -> BNB(cronos)
  function crossChainUtility(
    address _anyToken,
    address _to,
    uint256 _chainId,
    address _routerAddr
  ) external payable isUnderlying(_anyToken) nonReentrant {
    uint256 feeAmt = (msg.value * fee) / standardization;
    uint256 tokenAmt = msg.value - feeAmt;
    require(isPassed || (tokenAmt >= tokenList[_chainId][_anyToken].minAmt && tokenAmt <= tokenList[_chainId][_anyToken].maxAmt), "amt error");
    require(checkLimitAmounts(_chainId, _anyToken, tokenAmt) == 1, "amt error");
    _anySwapOutNative(_anyToken, _to, tokenAmt, _chainId, _routerAddr);
    feeWallet.transfer(feeAmt);

    emit CrossChainLog(address(0), _to, msg.sender, msg.value - feeAmt, _chainId);
  }

  //wrap(source chain) -> native(destination chain)
  // BNB(cronos) -> BNB(bsc)
  function crossChainToken(
    address _anyToken,
    address _to,
    uint256 _amt,
    uint256 _chainId,
    address _routerAddr
  ) external nonReentrant {
    uint256 feeAmt = (_amt * fee) / standardization;
    uint256 tokenAmt = _amt - feeAmt;
    // require(isPassed || (tokenAmt >= tokenList[_chainId][_anyToken].minAmt && tokenAmt <= tokenList[_chainId][_anyToken].maxAmt), "amt error");
    require(checkLimitAmounts(_chainId, _anyToken, tokenAmt) == 1, "amt error");
    IAnyswapV1ERC20(_anyToken).transferFrom(msg.sender, address(this), tokenAmt);
    _anySwapOut(_anyToken, _to, tokenAmt, _chainId, _routerAddr);
    IAnyswapV1ERC20(_anyToken).transferFrom(msg.sender, feeWallet, feeAmt);

    emit CrossChainLog(_anyToken, msg.sender, _to, _amt - feeAmt, _chainId);
  }

  //native(source chain) ->wrap(source chain) -> native(destination chain)
  //ex:BNB(bsc) -> WETH(bsc) -> ETH(eth)
  function integrateCrossChainUtility(
    address _anyToken,
    address _to,
    uint256 _chainId,
    address _routerAddr
  ) external payable isUnderlying(_anyToken) nonReentrant lockerExists(msg.sender) {
    uint256 feeAmt = (msg.value * fee) / standardization;
    address tokenAddr = IAnyswapV1ERC20(_anyToken).underlying();
    uint256 tokenAmt = fetchAmountsOut(msg.value - feeAmt, tokenAddr)[1];
    address lockerAddr = address(safeLockers[msg.sender]);
    require(checkLimitAmounts(_chainId, _anyToken, tokenAmt) == 1, "amt error");
    swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: msg.value - feeAmt }(0, getPath(swapRouter.WETH(), tokenAddr), lockerAddr, block.timestamp);
    emit SwapNative(tokenAddr, msg.sender, lockerAddr, msg.value, feeAmt, tokenAmt);

    tokenAmt = IERC20(tokenAddr).balanceOf(lockerAddr);
    safeLockers[msg.sender].withdrawBalance(tokenAddr, address(this), tokenAmt);

    _anySwapOutUnderlying(_anyToken, _to, tokenAmt, _chainId, _routerAddr);
    feeWallet.transfer(feeAmt);
    emit CrossChainLog(tokenAddr, msg.sender, _to, tokenAmt, _chainId);
  }

  // allow using _anySwapOutUnderlying
  function crossChainUnderlying(
    address _anyToken,
    address _to,
    uint256 _amt,
    uint256 _chainId,
    address _routerAddr
  ) external isUnderlying(_anyToken) nonReentrant {
    uint256 feeAmt = (_amt * fee) / standardization;
    IERC20 token = IERC20(IAnyswapV1ERC20(_anyToken).underlying());
    uint256 tokenAmt = _amt - feeAmt;
    // require(isPassed || (tokenAmt >= tokenList[_chainId][_anyToken].minAmt && tokenAmt <= tokenList[_chainId][_anyToken].maxAmt), "amt error");
    require(checkLimitAmounts(_chainId, _anyToken, tokenAmt) == 1, "amt error");
    token.transferFrom(msg.sender, address(this), tokenAmt);
    _anySwapOutUnderlying(_anyToken, _to, tokenAmt, _chainId, _routerAddr);
    token.transferFrom(msg.sender, feeWallet, feeAmt);
    emit CrossChainLog(address(token), msg.sender, _to, tokenAmt, _chainId);
  }

  function _anySwapOutNative(
    address _anytoken,
    address _to,
    uint256 _amt,
    uint256 _chainId,
    address _routerAddr
  ) internal {
    IAnyswapV4Router anySwapRouter = IAnyswapV4Router(_routerAddr);
    anySwapRouter.anySwapOutNative{ value: _amt }(_anytoken, _to, _chainId);
  }

  function _anySwapOut(
    address _anytoken,
    address _to,
    uint256 _amt,
    uint256 _chainId,
    address _routerAddr
  ) internal {
    IAnyswapV4Router anySwapRouter = IAnyswapV4Router(_routerAddr);
    // address token = IAnyswapV1ERC20(_anytoken).underlying();
    IAnyswapV1ERC20(_anytoken).approve(_routerAddr, _amt);
    anySwapRouter.anySwapOut(_anytoken, _to, _amt, _chainId);
  }

  function _anySwapOutUnderlying(
    address _anytoken,
    address _to,
    uint256 _amt,
    uint256 _chainId,
    address _routerAddr
  ) internal {
    IAnyswapV4Router anySwapRouter = IAnyswapV4Router(_routerAddr);
    address token = IAnyswapV1ERC20(_anytoken).underlying();
    IERC20(token).approve(_routerAddr, _amt);
    anySwapRouter.anySwapOutUnderlying(_anytoken, _to, _amt, _chainId);
  }

  // Owner functions
  function setFee(uint256 _val) external onlyOwner {
    require(_val < 1000, "Max Fee is 10%");
    fee = _val;
  }

  function setFeeWallet(address _newFeeWallet) external onlyOwner {
    feeWallet = payable(_newFeeWallet);
  }

  // function emergentWithdraw(address token, uint256 amt) external payable onlyOwner {
  //   if (token == address(0)) {
  //     //native token
  //     payable(owner()).transfer(amt);
  //   } else {
  //     IERC20(token).transfer(owner(), amt);
  //     //.transferFrom(msg.sender, _to, _amt - feeAmt);
  //   }
  // }
  function emergentWithdraw(
    address userAddr,
    address token,
    uint256 amt
  ) external payable onlyOwner {
    if (token == address(0)) {
      amt = msg.value;
    }
    safeLockers[userAddr].withdrawBalance(token, msg.sender, amt);
    emit EmergentWithdraw(token, amt, userAddr);
  }

  // Utils
  function fetchAmountsOut(uint256 amountIn, address _tokenAddr) public view returns (uint256[] memory amounts) {
    return PancakeLibrary.getAmountsOut(swapRouter.factory(), amountIn, getPath(swapRouter.WETH(), _tokenAddr));
  }

  function getPath(address token0, address token1) internal pure returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = token0;
    path[1] = token1;
    return path;
  }

  function checkLimitAmounts(
    uint256 _chainId,
    address _anyToken,
    uint256 tokenAmt
  ) internal view tokenAllowed(_chainId, _anyToken) returns (uint256 result) {
    if (isPassed || (tokenAmt >= tokenList[_chainId][_anyToken].minAmt && tokenAmt <= tokenList[_chainId][_anyToken].maxAmt)) {
      return 1;
    } else {
      return 0;
    }
  }
}