/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

//SPDX-license-Identifier: MIT
pragma solidity ^0.8;
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
// import "./Uniswap.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address _sender,
        uint _amount0,
        uint _amount1,
        bytes calldata _data
    ) external;
}

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[]   memory path)
      external
      view
      returns(uint[] memory amounts);
      
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    
    function token1() external view returns (address);
    
    function swap(
        uint amount0Out, 
        uint amount1Out, 
        address to, 
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external view returns (address);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
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
    function transferFrom(
        address sender,
        address recipient,
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

contract  unisushi is IUniswapV2Callee {
    // address private constant WETH    = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;    //weth address on eth.co
    // address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant uni_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;    // uniswap v2 FACTORY
    address private constant sushi_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //sushi == uni
    address private constant SUSHISWAP_V2_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    
    address payable receiveAddress;
    uint constant deadline = 10 minutes; 
    event Log(string message, uint vol);
    address[3] path;
    bool locate;
    
    function testFlashSwap(address[] memory _tokens, uint _amount, address _pairBorrow, address payable myAddress,  bool _locate) external {
        // address[] memory _tokens = [A.B,C]  ???A??????????????????B???C??????????????????   ??????, ?????????pairaddress, ????????????)   
        //?????????????????????????????? ????????????,4???pair(??????pair,ABpair, BCpair, CApair )???3????????????_locate???_locate {true:uni, false:sushi}  [A,B,C] 
        //??????????????? ???????????????3???pair(??????pair = _pairBorrow, uni pair, sushi pair) _locate {uni -> sushi. false sushi -> uni}  [A,B] 

        require(_tokens.length > 1, "!input address");   //???????????????
        for(uint i; i < _tokens.length; i++){
            path[i] = _tokens[i];
        }
        receiveAddress = myAddress;
        locate = _locate;
        //######  ??????,  _pairBorrow ??????uniswap or sushiswap
        address _tokenBorrow = path[0]; //
        require(_pairBorrow != address(0), "!pairsBorrow");   //???????????????

        address token0 = IUniswapV2Pair(_pairBorrow).token0();
        address token1 = IUniswapV2Pair(_pairBorrow).token1(); //???????????????????????????

        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;  //jugle which usdc

        bytes memory data = abi.encode(_tokenBorrow, _amount);
        IUniswapV2Pair(_pairBorrow).swap(amount0Out, amount1Out, address(this), data);
    } 
    
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external override {
      //_sender: smartcontract address
      
      address tokenA = IUniswapV2Pair(msg.sender).token0();   //????????????????????????
      address tokenB = IUniswapV2Pair(msg.sender).token1();
      
      address FACTORY = locate? uni_FACTORY : sushi_FACTORY;
      address pair = IUniswapV2Factory(FACTORY).getPair(tokenA, tokenB);  //path[0],path[1]
      (address tokenBorrow, uint amount) = abi.decode(_data, (address, uint));//??????????????????????????????
      
      require(msg.sender == pair, "!pair");                         //make sure
      require(_sender == address(this), "!sender");                 //make sure sender is urself
      require(tokenBorrow == tokenA || tokenBorrow == tokenB, "!tokenBorrow"); 
        
      uint fee = ((amount*3)/997) + 1;
      uint amountToRepay = amount + fee;
      
      //....................my staff .......
      uint _amountOutMin;   //?????????borrow?????????
      address[] memory paths = new address[](3);
      address[] memory path_return = new address[](2);
      for(uint i; i < path.length; i++){
            paths[i] = path[i];
        }
      address dex_ROUTER = locate? UNISWAP_V2_ROUTER : SUSHISWAP_V2_ROUTER; //???????????????????????????????????? ?????? ???????????????????????????????????????????????????????????????
      
      if (path[2] != address(0)) { //????????????,3????????????????????????   A -> B   B -> C  C->A   ???????????????A -> C
        
        //first swap A -> C
        IERC20(tokenBorrow).approve(dex_ROUTER, amount);  // use A
        uint _amountOutMin3 = IUniswapV2Router(dex_ROUTER).getAmountsOut(amount, paths)[1]; //???????????????????????????
        IUniswapV2Router(dex_ROUTER).swapExactTokensForTokens(amount, _amountOutMin3, paths, address(this), deadline);  //???????????????????????????  path[0] -> path[2]
        //????????????????????????

        //second swap C -> A
        path_return[0] = path[2];
        path_return[1] = tokenBorrow;
        IERC20(path[2]).approve(dex_ROUTER, _amountOutMin3);  // use C
        _amountOutMin = IUniswapV2Router(dex_ROUTER).getAmountsOut(_amountOutMin3, path_return)[1];
        IUniswapV2Router(dex_ROUTER).swapExactTokensForTokens(_amountOutMin3, _amountOutMin, path_return, address(this), deadline);
        }
      else { //????????????, ?????????????????????
        //_tokenBorrow = path[0]
        require(path[1] != address(0), "address is wrong!");
        address tokenOut = path[1];
        
        // first swap  tokenBorrow -> tokenOut   or A -> B
        address[] memory path_go = new address[](2);
        path_go[0] = tokenBorrow; 
        path_go[1] = tokenOut;  
        IERC20(tokenBorrow).approve(dex_ROUTER, amount);
        uint _amountOutMin2 = IUniswapV2Router(dex_ROUTER).getAmountsOut(amount, path_go)[1];  //[in , out]
        IUniswapV2Router(dex_ROUTER).swapExactTokensForTokens(amount, _amountOutMin2, path_go, address(this), deadline);   //address(this) = a

        //second swap   tokenOut -> tokenBorrow  or B -> A
        address second_ROUTER = locate? SUSHISWAP_V2_ROUTER : UNISWAP_V2_ROUTER;   
        path_return[0] = tokenOut;
        path_return[1] = tokenBorrow;

        IERC20(tokenOut).approve(second_ROUTER, _amountOutMin2);
        _amountOutMin = IUniswapV2Router(second_ROUTER).getAmountsOut(_amountOutMin2, path_go)[1];  //[in , out]
        IUniswapV2Router(second_ROUTER).swapExactTokensForTokens(_amountOutMin2, _amountOutMin, path_go, address(this), deadline);   //address(this) = a

      }
      
      require(_amountOutMin > amountToRepay, "can not arbitrage!");
      IERC20(tokenBorrow).transfer(pair, amountToRepay);  //???????????????
      IERC20(tokenBorrow).transfer(receiveAddress, _amountOutMin-amountToRepay);  //????????????????????????
      emit Log("profit", _amountOutMin-amountToRepay); //????????????
    }
    
    fallback() external payable {
        
    }
}