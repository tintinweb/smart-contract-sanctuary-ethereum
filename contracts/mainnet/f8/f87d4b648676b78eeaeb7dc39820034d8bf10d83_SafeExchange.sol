//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Utils.sol";
import "./DexUtils.sol";
import "./CrossChainLocker.sol";


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
    //swapRouter = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); //  polygon

    // swapRouter = IUniswapV2Router02(_uniSwapAddr);
    // anySwapRouter = IAnyswapV4Router(_anySwapAddr);
    feeWallet = payable(_feeWallet);
    fee = 100;

    // init add anyTokenList//
    // //bsc//
    // 000000000000000000
    isPassed = false;
    //addToken(25, 0xEDF0c420bc3b92B961C6eC411cc810CA81F5F21a, 12000000000000000000, 20000000000000000000000000); // USDT -> chain25 (0.02 , 11000 )
    //addToken(1, 0xDebB1d6a2196F2335aD51FBdE7Ca587205889360, 20000000000000000, 9640000000000000000000); // ETH(02 , 9640 )
    //addToken(137, 0xBF731BFa03E0095A2039E7E4C3B466eFB7F3Ec4E, 5000000000000000000, 2500000000000000000000000); // MATIC(5 , 2500000 )
    // //eth//
    //addToken(56, 0x22648C12acD87912EA1710357B1302c6a4154Ebc, 12000000, 20000000000000); // USDT -> chain56 (,105000000)
    // //polygon//
    addToken(56, 0xE3eeDa11f06a656FcAee19de663E84C7e61d3Cac, 12000000, 20000000000000); // USDT-> chain56(12, 20000000))
     //cronos//
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