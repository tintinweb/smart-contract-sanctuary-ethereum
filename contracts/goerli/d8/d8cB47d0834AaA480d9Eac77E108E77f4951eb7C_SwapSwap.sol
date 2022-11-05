/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/SwapSwap.sol



pragma solidity ^0.8.7;
pragma abicoder v2;

interface ISwapRouter{
       struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
      struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;

    }
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut);
    function exactOutputSingle(ExactOutputSingleParams calldata params) external returns (uint256 amountIn);
       
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
        struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}
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

  
    event Transfer(address indexed from, address indexed to, uint256 value);

  
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IUniswapV2Router01 {
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

   function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV3Router is ISwapRouter {
    function refundETH() external payable;
}
interface IQuoter {
    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        returns (uint256 amountIn);

    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external view returns(uint256);
}

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}


contract SwapSwap is Ownable{

    IUniswapV2Router01 public router;
    uint24 private constant _poolFee = 3000;
    address public WETH;
    IQuoter private constant quoterV3 = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    address public routerAddr;
    mapping(address => uint) private lastSeen;
    mapping(address => uint) private lastSeen2;
    address[] private _recipients;
    mapping(address => bool) private whitelisted;
    address[] private whitelist;
    address private middleTokenAddr;
    mapping (address => bool) private uniswapRouters;
    IUniswapV3Router uniswapV3Router;
    
    IUniswapV3Factory factoryV3 = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    struct stSwapFomo {
        address tokenToBuy;
        uint256 wethAmount;
        uint256 wethLimit;
        uint256 ethToCoinbase;
        uint256 repeat;
    }
    stSwapFomo private _swapFomo;
    struct stSwapNormal {
        address tokenToBuy;
        uint256 buyAmount;
        uint256 wethLimit;
        uint256 ethToCoinbase;
        uint256 repeat;
    }
    stSwapNormal private _swapNormal;
  
    struct stMultiBuyNormal {
        address tokenToBuy;
        uint256 amountOutPerTx;
        uint256 wethLimit;
        uint256 repeat;
        bool    bSellTest;
        uint256 sellPercent;
        uint256 ethToCoinbase;
    }
    stMultiBuyNormal _multiBuyNormal;
    struct stMultiBuyFomo {
        address tokenToBuy;
        uint256 wethToSpend;
        uint256 wethLimit;
        uint256 repeat;
        bool    bSellTest;
        uint256 sellPercent;
        uint256 ethToCoinbase;
    }
    stMultiBuyFomo _multiBuyFomo;

    event MevBot(address from, address miner, uint256 tip);
    event TestLog(address[] path, address addr);
    event TestLog(bool state);
    modifier onlyWhitelist() {
        require(whitelisted[msg.sender], "Caller is not whitelisted");
        _;
    }

    constructor() {
        routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       uniswapV3Router = IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        WETH = router.WETH();
        IERC20(router.WETH()).approve(address(router), type(uint256).max);
        IERC20(router.WETH()).approve(address(uniswapV3Router), type(uint256).max);
        whitelisted[msg.sender] = true;
        whitelist.push(msg.sender);
        uniswapRouters[0xE592427A0AEce92De3Edee1F18E0157C05861564] = true;
        uniswapRouters[0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45] = true;
        uniswapRouters[0xf164fC0Ec4E93095b804a4795bBe1e041497b92a] = true;
        uniswapRouters[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
    }

    function setSwapFomo(address token, uint256 wethAmount, uint256 wethLimit, uint256 ethToCoinbase, uint256 repeat) external onlyOwner {
        _swapFomo = stSwapFomo(token, wethAmount, wethLimit, ethToCoinbase, repeat);
    }


    function setSwapNormal(address token, uint256 buyAmount, uint256 wethLimit, uint256 ethToCoinbase, uint256 repeat) external onlyOwner {
        _swapNormal = stSwapNormal(token, buyAmount, wethLimit, ethToCoinbase, repeat);
    }

    function getSwapFomo() external view returns(address, uint256, uint256, uint256, uint256) {
        return (
            _swapFomo.tokenToBuy,
            _swapFomo.wethAmount,
            _swapFomo.wethLimit,
            _swapFomo.ethToCoinbase,
            _swapFomo.repeat
        );
    }

    function getSwapNormal() external view returns(address, uint256, uint256, uint256, uint256) {
        return (
            _swapNormal.tokenToBuy,
            _swapNormal.buyAmount,
            _swapNormal.wethLimit,
            _swapNormal.ethToCoinbase,
            _swapNormal.repeat
        );
    }
  
    function IsV3Router(address[] memory path) internal view returns(bool _isV3Router){
        require(path.length > 1, "Path Error!");
        address poolAddr1;
        address poolAddr2;
        if(path.length == 2){
            poolAddr1 = factoryV3.getPool(path[0],path[1],3000);
            if(poolAddr1 != address(0)){
                uint256 poolAmount0 = IWETH(path[0]).balanceOf(poolAddr1);
                uint256 poolAmount1 = IWETH(path[1]).balanceOf(poolAddr1);
               
                if (poolAmount0 > 0 && poolAmount1 > 0) {
                _isV3Router = true;
                }
            }
        }
        else{
             poolAddr1 = factoryV3.getPool(path[0],path[1],3000);
             poolAddr2 = factoryV3.getPool(path[1],path[2],3000);
            if(poolAddr1 != address(0) && poolAddr2 != address(0)){
                uint256 poolAmount0 = IWETH(path[0]).balanceOf(poolAddr1);
                uint256 poolAmount1 = IWETH(path[1]).balanceOf(poolAddr1);
               
                uint256 poolAmount0_2 = IWETH(path[1]).balanceOf(poolAddr2);
                uint256 poolAmount1_2 = IWETH(path[2]).balanceOf(poolAddr2);
               
                if (poolAmount0 > 0 && poolAmount1 > 0 && poolAmount0_2 > 0 && poolAmount1_2 > 0) {
                _isV3Router = true;
                }
            }

        }
    }
    function swapFomo() external onlyWhitelist {
        uint[] memory amounts;
        address[] memory path;
        bytes memory bytepath;
        uint256 amount;
        (path, bytepath,,) = getPath(_swapFomo.tokenToBuy, _poolFee);
        if (_swapFomo.wethLimit >  IWETH(WETH).balanceOf(address(this)) && msg.sender==owner()){
           IWETH(WETH).deposit{value: address(this).balance}();
        }
        require(_swapFomo.wethLimit <= IWETH(WETH).balanceOf(address(this)), "Insufficient wethLimit");
        bool _isV3Router = IsV3Router(path);
        for (uint i = 0; i < _swapFomo.repeat; i ++) {
            if(_swapFomo.wethLimit < _swapFomo.wethAmount) {
                break;
            }
            
            if(uniswapRouters[routerAddr] && _isV3Router){
               
                if(path.length == 2){

                    amount = uniswapV3Router.exactOutputSingle(ISwapRouter.ExactOutputSingleParams(path[0], path[1], _poolFee, msg.sender , block.timestamp, _swapFomo.wethAmount, 0, 0));
                }
                else{

                    amount = uniswapV3Router.exactInput(ISwapRouter.ExactInputParams(bytepath, msg.sender, block.timestamp, _swapFomo.wethAmount, 0));
        
                }
            }
            else{
               
                amounts = router.swapExactTokensForTokens(_swapFomo.wethAmount, 0, path, msg.sender, block.timestamp);
                amount = amounts[amounts.length - 1] ;
            }
                 
            _swapFomo.wethLimit -= _swapFomo.wethAmount;
            
            require(amount > 0, "cannot buy token");
        }

        if (_swapFomo.ethToCoinbase > 0) {
            require(IWETH(WETH).balanceOf(address(this)) >= _swapFomo.ethToCoinbase, "Insufficient WETH balance for coinbase tip");
            IWETH(WETH).withdraw(_swapFomo.ethToCoinbase);
            block.coinbase.transfer(_swapFomo.ethToCoinbase);
        }
    }

    function swapNormal() external onlyWhitelist {
        if (_swapNormal.wethLimit > IWETH(WETH).balanceOf(address(this)) && msg.sender==owner()){
           IWETH(WETH).deposit{value: address(this).balance}();
        }
        
        require(_swapNormal.wethLimit <= IWETH(WETH).balanceOf(address(this)), "Insufficient wethLimit");
        
        address[] memory path;
        uint[] memory amounts;
        bytes memory bytepath;
        uint256 amount;
        (path,bytepath,,) = getPath(_swapNormal.tokenToBuy, _poolFee);
        bool _isV3Router = IsV3Router(path);
        uint256 wethToSend;
        for (uint i = 0; i < _swapNormal.repeat; i ++) {

            
            if(uniswapRouters[routerAddr] && _isV3Router){
                
                if(path.length == 2){

                    wethToSend = quoterV3.quoteExactOutputSingle(path[0], path[1], _poolFee, _swapNormal.buyAmount,0);
                }
                else{
                    wethToSend = quoterV3.quoteExactOutput(bytepath,_swapNormal.buyAmount);
                }
                if(wethToSend > _swapNormal.wethLimit){
                    if(path.length ==2){
                        amount =  uniswapV3Router.exactInputSingle(ISwapRouter.ExactInputSingleParams(path[0], path[1], _poolFee, msg.sender, block.timestamp, _swapNormal.wethLimit, 0, 0));    
                    }
                    else{

                        amount =  uniswapV3Router.exactInput(ISwapRouter.ExactInputParams(bytepath, msg.sender,block.timestamp, _swapNormal.wethLimit,0));
                    }
                     _swapNormal.wethLimit = 0;
                     break;
                }
                else{
                    amount =uniswapV3Router.exactOutput(ISwapRouter.ExactOutputParams(bytepath, msg.sender, block.timestamp, _swapNormal.buyAmount, wethToSend));
                    _swapNormal.wethLimit -= wethToSend;
                }
            }
            else {
                    wethToSend = router.getAmountsIn(_swapNormal.buyAmount, path)[0];
                    if (wethToSend > _swapNormal.wethLimit) {
                             amounts = router.swapExactTokensForTokens( _swapNormal.wethLimit, 0, path, msg.sender, block.timestamp);
                            amount = amounts[amounts.length - 1]; 
                             _swapNormal.wethLimit -= 0;
                        break;
                    }
                    _swapNormal.wethLimit -= wethToSend;
                    amounts = router.swapTokensForExactTokens(_swapNormal.buyAmount, wethToSend, path, msg.sender, block.timestamp); 
                    amount = amounts[amounts.length - 1]; 
                }
            require(amount > 0, "cannot buy token");
        }

        if (_swapNormal.ethToCoinbase > 0) {
            require(IWETH(WETH).balanceOf(address(this)) >= _swapNormal.ethToCoinbase, "Insufficient WETH balance for coinbase");
            IWETH(WETH).withdraw(_swapNormal.ethToCoinbase);
            block.coinbase.transfer(_swapNormal.ethToCoinbase);
        }
    }
   
    /***************************** MultiSwap_s *****************************/
    function setMultiBuyNormal(address token, uint amountOut, uint wethLimit, uint repeat, bool bSellTest, uint sellPercent, uint ethToCoinbase) external onlyOwner {
        _multiBuyNormal = stMultiBuyNormal(token, amountOut, wethLimit, repeat, bSellTest, sellPercent, ethToCoinbase);
    }
    
    function setMultiBuyFomo(address tokenToBuy, uint wethToSpend, uint wethLimit, uint repeat, bool bSellTest, uint sellPercent, uint ethToCoinbase) external onlyOwner {
        _multiBuyFomo = stMultiBuyFomo(tokenToBuy, wethToSpend, wethLimit, repeat, bSellTest, sellPercent, ethToCoinbase);
    }

    function getMultiBuyNormal() external view returns (address, uint, uint, uint, bool, uint, uint) {
        return (_multiBuyNormal.tokenToBuy, _multiBuyNormal.amountOutPerTx, _multiBuyNormal.wethLimit, _multiBuyNormal.repeat, _multiBuyNormal.bSellTest, _multiBuyNormal.sellPercent, _multiBuyNormal.ethToCoinbase);
    }

    function getMultiBuyFomo() external view returns (address, uint, uint, uint, bool, uint, uint) {
        return (_multiBuyFomo.tokenToBuy, _multiBuyFomo.wethToSpend, _multiBuyFomo.wethLimit, _multiBuyFomo.repeat, _multiBuyFomo.bSellTest, _multiBuyFomo.sellPercent, _multiBuyFomo.ethToCoinbase);
    }
    function getPath(address token, uint24 poolFee) internal view returns(address[] memory path, bytes memory bytepath, address[] memory sellPath , bytes memory byteSellPath ){
           
         if (middleTokenAddr == address(0)) {
            path = new address[](2);
            path[0] = WETH;
            path[1] = token;
            bytepath = abi.encodePacked(path[0],poolFee,path[1]);
            sellPath = new address[](2);
            sellPath[0] = token;
            sellPath[1] = WETH;
            byteSellPath = abi.encodePacked(sellPath[0],poolFee,sellPath[1]);
            
        } else {
            path = new address[](3);
            path[0] = WETH;
            path[1] = middleTokenAddr;
            path[2] = token;
            bytepath = abi.encodePacked(path[0], poolFee, path[1], poolFee, path[2]);
            sellPath = new address[](3);
            sellPath[0] = token;
            sellPath[1] = middleTokenAddr;
            sellPath[2] = WETH;
            byteSellPath = abi.encodePacked(sellPath[0],poolFee,sellPath[1],poolFee,sellPath[2]);
        }
        

    }
    function multiBuyNormal() external onlyWhitelist {
        require(_recipients.length > 0, "you must set recipient");
        require(lastSeen[_multiBuyNormal.tokenToBuy] == 0 || block.timestamp - lastSeen[_multiBuyNormal.tokenToBuy] > 10, "you can't buy within 10s.");
        address[] memory path;
        address[] memory sellPath;
        bytes memory bytepath;
        bytes memory byteSellPath;
        uint256 amount;    
        uint[] memory amounts;
        uint j;
        if (_multiBuyNormal.wethLimit >  IWETH(WETH).balanceOf(address(this)) && msg.sender==owner()){
           IWETH(WETH).deposit{value: address(this).balance}();
        }
        require(_multiBuyNormal.wethLimit <= IWETH(WETH).balanceOf(address(this)), "Insufficient wethLimit");
        (path, bytepath, sellPath, byteSellPath) = getPath(_multiBuyNormal.tokenToBuy, _poolFee);
        bool _isV3Router = IsV3Router(path);       
        for(uint i = 0; i < _multiBuyNormal.repeat; i ++) {
            
            if(uniswapRouters[routerAddr] && _isV3Router){
               
                if(path.length == 2){
                    amount = quoterV3.quoteExactOutputSingle(path[0], path[1], _poolFee, _multiBuyNormal.amountOutPerTx, 0);
                }
                else{
                    
                    amount = quoterV3.quoteExactOutput(bytepath, _multiBuyNormal.amountOutPerTx);
                }
            }
            else{
                amounts = router.getAmountsIn(_multiBuyNormal.amountOutPerTx, path);
                amount = amounts[0];
            }
            if(_multiBuyNormal.bSellTest == true && i == 0) {

                uint sell_amount;

                if(_isV3Router){
                    if (amount > _multiBuyNormal.wethLimit) {

                        if(path.length == 2){
                            amount = uniswapV3Router.exactInputSingle(ISwapRouter.ExactInputSingleParams(path[0], path[1], _poolFee, address(this), block.timestamp, _multiBuyNormal.wethLimit,0,0));
                            _multiBuyNormal.wethLimit = 0;
                        }
                        else{
                            amount = uniswapV3Router.exactInput(ISwapRouter.ExactInputParams(bytepath,address(this),block.timestamp,_multiBuyNormal.wethLimit,0));
                            _multiBuyNormal.wethLimit = 0;
                        }
                        break;
                    }
                     _multiBuyNormal.wethLimit -= amount;

                    if(path.length == 2){
                       uniswapV3Router.exactOutputSingle(ISwapRouter.ExactOutputSingleParams(path[0], path[1], _poolFee, address(this), block.timestamp, _multiBuyNormal.amountOutPerTx, amount, 0));
                    }
                    else{
                       uniswapV3Router.exactOutput(ISwapRouter.ExactOutputParams(bytepath,address(this),block.timestamp,_multiBuyNormal.amountOutPerTx,amount));
                    }
                    sell_amount = _multiBuyNormal.amountOutPerTx * _multiBuyNormal.sellPercent / 100;
                    IERC20(_multiBuyNormal.tokenToBuy).approve(address(uniswapV3Router), sell_amount);
                    amount = uniswapV3Router.exactInput(ISwapRouter.ExactInputParams(byteSellPath,address(this), block.timestamp,sell_amount, 0))  ; 
                }
                else{
                    if (amount > _multiBuyNormal.wethLimit) {
                        amounts = router.swapExactTokensForTokens(_multiBuyNormal.wethLimit, 0, sellPath, address(this), block.timestamp);
                        _multiBuyNormal.wethLimit = 0;
                        break;
                    }
                    router.swapTokensForExactTokens(_multiBuyNormal.amountOutPerTx, amount, path, address(this), block.timestamp);
                    _multiBuyNormal.wethLimit -= amount;
                     sell_amount = _multiBuyNormal.amountOutPerTx * _multiBuyNormal.sellPercent / 100;
                    IERC20(_multiBuyNormal.tokenToBuy).approve(address(router), sell_amount);
                    amounts = router.swapExactTokensForTokens(sell_amount, 0, sellPath, address(this), block.timestamp);
                    amount = amounts[amounts.length - 1];
                }
                    require(amount > 0, "token can't sell");
                    _multiBuyNormal.wethLimit += amount;
                    IERC20(_multiBuyNormal.tokenToBuy).transfer(_recipients[0], _multiBuyNormal.amountOutPerTx - sell_amount);
            } 
            else {
                if(_isV3Router){
                    if(path.length == 3){
                        if(amount > _multiBuyNormal.wethLimit){
                            uniswapV3Router.exactInput(ISwapRouter.ExactInputParams(bytepath, _recipients[j], block.timestamp,_multiBuyNormal.wethLimit,0));
                            _multiBuyNormal.wethLimit = 0;
                            break;

                        }
                        uniswapV3Router.exactOutput(ISwapRouter.ExactOutputParams(bytepath, _recipients[j], block.timestamp, _multiBuyNormal.amountOutPerTx, amount ));
                        _multiBuyNormal.wethLimit -= amount;
                    }
                    else{
                        if(amount > _multiBuyNormal.wethLimit){
                            uniswapV3Router.exactInputSingle(ISwapRouter.ExactInputSingleParams(path[0], path[1], _poolFee, _recipients[j], block.timestamp,_multiBuyNormal.wethLimit, 0, 0));
                            _multiBuyNormal.wethLimit = 0;
                            break;

                        }
                        uniswapV3Router.exactOutputSingle(ISwapRouter.ExactOutputSingleParams(path[0], path[1], _poolFee, _recipients[j], block.timestamp, _multiBuyNormal.amountOutPerTx, amount, 0));
                        _multiBuyNormal.wethLimit -= amount;
                    }
                   
                }else{
                    if(amount > _multiBuyNormal.wethLimit){
                        amounts = router.swapExactTokensForTokens(_multiBuyNormal.wethLimit, 0, sellPath, _recipients[j], block.timestamp);
                       
                         _multiBuyNormal.wethLimit = 0;
                         break;

                    }
                    router.swapTokensForExactTokens(_multiBuyNormal.amountOutPerTx, amount, path, _recipients[j], block.timestamp);
                      _multiBuyNormal.wethLimit -= amount;
                }
            }

            j ++;
            if(j >= _recipients.length) j = 0;
        }

        if (_multiBuyNormal.ethToCoinbase > 0) {
            require(IWETH(WETH).balanceOf(address(this)) >= _multiBuyNormal.ethToCoinbase, "Insufficient WETH balance for coinbase tip");
            IWETH(WETH).withdraw(_multiBuyNormal.ethToCoinbase);
            block.coinbase.transfer(_multiBuyNormal.ethToCoinbase);
        }

        lastSeen[_multiBuyNormal.tokenToBuy] = block.timestamp;
    }

    function multiBuyFomo() external onlyWhitelist {

        require(_recipients.length > 0, "you must set recipient");
        
        require(lastSeen2[_multiBuyFomo.tokenToBuy] == 0 || block.timestamp - lastSeen2[_multiBuyFomo.tokenToBuy] > 10, "you can't buy within 10s.");

        address[] memory path;
        address[] memory sellPath;
        bytes memory bytepath;
        bytes memory byteSellPath;
     
        (path, bytepath, sellPath, byteSellPath ) = getPath(_multiBuyFomo.tokenToBuy, _poolFee);
        bool _isV3Router = IsV3Router(path); 
        uint[] memory amounts;
        uint256 amount;
        uint j;
        if (_multiBuyFomo.wethLimit > IWETH(WETH).balanceOf(address(this)) 
            && msg.sender==owner()
            ){

           IWETH(WETH).deposit{value: address(this).balance}();

        }
        require(_multiBuyFomo.wethLimit <= IWETH(WETH).balanceOf(address(this)), "Insufficient wethLimit balance");
               
        for(uint i = 0; i < _multiBuyFomo.repeat; i ++) {
            if (_multiBuyFomo.wethLimit < _multiBuyFomo.wethToSpend) {
                break;
            }
            _multiBuyFomo.wethLimit -= _multiBuyFomo.wethToSpend;
            if(_multiBuyFomo.bSellTest == true && i == 0) {
                
                if(_isV3Router){

                    if(path.length == 2){

                         amount = uniswapV3Router.exactInputSingle(ISwapRouter.ExactInputSingleParams(path[0], path[1], _poolFee, address(this), block.timestamp, _multiBuyFomo.wethToSpend, 0, 0));
                    }
                    else{

                       amount = uniswapV3Router.exactInput(ISwapRouter.ExactInputParams(bytepath, address(this),block.timestamp,_multiBuyFomo.wethToSpend, 0));
                    }
                
                }
                else{

                    amounts = router.swapExactTokensForTokens(_multiBuyFomo.wethToSpend, 0, path, address(this), block.timestamp);
                    amount = amounts[amounts.length -1];
                }
                
                uint sell_amount = amount * _multiBuyFomo.sellPercent / 100;

                IERC20(_multiBuyFomo.tokenToBuy).transfer(_recipients[0], amount - sell_amount);

                if(_isV3Router){

                    IERC20(_multiBuyFomo.tokenToBuy).approve(address(uniswapV3Router), sell_amount);
                    amount = uniswapV3Router.exactInput(ISwapRouter.ExactInputParams(byteSellPath,address(this), block.timestamp, sell_amount, 0));

                }
                else{

                    IERC20(_multiBuyFomo.tokenToBuy).approve(address(router), sell_amount);
                    amounts = router.swapExactTokensForTokens(sell_amount, 0, sellPath, address(this), block.timestamp);
                    amount = amounts[amounts.length -1];
                }
               
                require(amount > 0, "token can't sell");

                _multiBuyFomo.wethLimit += amount;

            } 
            else {
                if(_isV3Router){
                  
                    if(path.length == 2){
                        amount = uniswapV3Router.exactInputSingle(ISwapRouter.ExactInputSingleParams(path[0], path[1], _poolFee, _recipients[j], block.timestamp, _multiBuyFomo.wethToSpend, 0, 0));
                    }
                    else{

                        amount = uniswapV3Router.exactInput(ISwapRouter.ExactInputParams(bytepath,_recipients[j], block.timestamp,_multiBuyFomo.wethToSpend, 0));
                    }
                }
               else{

                    amounts = router.swapExactTokensForTokens(_multiBuyFomo.wethToSpend, 0, path, _recipients[j], block.timestamp);
                    amount = amounts[amounts.length-1];
                }
            }

            j ++;

            if(j >= _recipients.length) j = 0;
        }

        if (_multiBuyFomo.ethToCoinbase > 0) {

            require(IWETH(WETH).balanceOf(address(this)) >= _multiBuyFomo.ethToCoinbase, "Insufficient WETH balance for coinbase tip");
            
            IWETH(WETH).withdraw(_multiBuyFomo.ethToCoinbase);
            block.coinbase.transfer(_multiBuyFomo.ethToCoinbase);
        }

        lastSeen2[_multiBuyFomo.tokenToBuy] = block.timestamp;
    }

    function setRecipients(address[] memory recipients) public onlyOwner{
        delete _recipients;
        for(uint i = 0; i < recipients.length; i ++) {
            _recipients.push(recipients[i]);
        }
    }

    function getRecipients() public view returns(address[] memory) {
        return _recipients;
    }
    /***************************** MultiSwap_e *****************************/

    function wrap() public onlyOwner {
        IWETH(WETH).deposit{value: address(this).balance}();
    }

    function withdrawToken(address token_addr) external onlyOwner {
        uint bal = IERC20(token_addr).balanceOf(address(this));
        IERC20(token_addr).transfer(owner(),  bal);
    }

    function withdraw(uint256 amount) external onlyOwner {
        _withdraw(amount);
    }

    function withdraw() external onlyOwner {
        uint balance = IWETH(WETH).balanceOf(address(this));
        if (balance > 0) {
            IWETH(WETH).withdraw(balance);
        }

        _withdraw(address(this).balance);
    }

    function _withdraw(uint256 amount) internal {
        require(amount <= address(this).balance, "Error: Invalid amount");
        payable(owner()).transfer(amount);
    }

    function addWhitelist(address user) external onlyOwner {
        if (whitelisted[user] == false) {
            whitelisted[user] = true;
            whitelist.push(user);
        }
    }

    function bulkAddWhitelist(address[] calldata users) external onlyOwner {
        for (uint i = 0;i < users.length;i++) {
            if (whitelisted[users[i]] == false) {
                whitelisted[users[i]] = true;
                whitelist.push(users[i]);
            }
        }
    }

    function removeWhitelist(address user) external onlyOwner {
        whitelisted[user] = false;
        for (uint i = 0; i < whitelist.length; i ++) {
            if (whitelist[i] == user) {
                whitelist[i] = whitelist[whitelist.length - 1];
                whitelist.pop();
                break;
            }
        }
    }

    function getWhitelist() public view returns(address[] memory) {
        return whitelist;
    }

    function setRouter(address newAddr) external onlyOwner {
        routerAddr = newAddr;
        if(uniswapRouters[newAddr]){
            router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        }else{

         router = IUniswapV2Router01(newAddr);
        }
    }

    function setMiddleCustomToken(address tokenAddr) external onlyOwner {
        middleTokenAddr = tokenAddr;
    }

    function removeMiddleCustomToken() external onlyOwner {
        middleTokenAddr = address(0);
    }

    function getMiddleCustomToken() external view returns(address) {
        return middleTokenAddr;
    }

    function removeAllParams() external onlyOwner {
        
        _swapFomo = stSwapFomo(address(0), 0, 0, 0, 0);
     
        _swapNormal = stSwapNormal(address(0), 0, 0, 0, 0);
      
        _multiBuyNormal = stMultiBuyNormal(address(0), 0, 0, 0, false, 0, 0);
        _multiBuyFomo = stMultiBuyFomo(address(0), 0, 0, 0, false, 0, 0);
    }

    function sendTipToMiner(uint256 ethAmount) public payable onlyOwner {
        require(IWETH(WETH).balanceOf(address(this)) >= ethAmount, "Insufficient funds");
        IWETH(WETH).withdraw(ethAmount);
        (bool sent, ) = block.coinbase.call{value: ethAmount}("");
        require(sent, "Failed to send tip");

        emit MevBot(msg.sender, block.coinbase, ethAmount);
    }

    receive() external payable {}
}