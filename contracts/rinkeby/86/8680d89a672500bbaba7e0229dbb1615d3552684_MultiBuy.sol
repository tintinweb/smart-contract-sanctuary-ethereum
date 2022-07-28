/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

  /**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    // receive () external payable virtual {
    //     _fallback();
    // }

   
}
abstract contract Ownable{
    address private _owner;
    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      _owner = newOwner;
    }
}

interface IUniswapV2Router {

    function swapExactTokensForTokens(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline) 
        external returns (uint256[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;  

    function factory() external pure returns (address);
}

interface IDexFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract MultiBuy is Ownable,Proxy{
    address internal _implement;
    IUniswapV2Router internal uniswapV2Router;
    IDexFactory internal dexFactory;
    address public SwapAddress;
    address public WETH;
    uint256 public amountIn;
    uint256 public amountOutMin;
    address[] public path = new address[](2) ;
    address[] public sellPath = new address[](2) ;
    address[] public toWallet;
    uint256 public BiGNum = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    
    uint256 public priceDecimal = 10 ** 18;
    uint256 public buyPrice = 0;
    uint256 public maxPrice = 0;
    //价格高点下跌百分多少就卖出 取值范围：1 - 100 , 100表示不卖出。 对于卖出后账户必须保留一定余额的场景，此处设置为100
    uint public priceDownPercent = 100;
    //相对买入价涨了百分之多少就卖出，取值范围：120 以上
    uint public priceUpPercent = 1000;
 
    function initialize(address _SwapAddress, address _WETH,uint256 _amountIn,uint256 _amountOutMin,address _fromContract,
                        address _toContract,address[] memory _toWallet,uint _priceUpPercent,uint _priceDownPercent) external onlyOwner {
        SwapAddress = _SwapAddress;
        uniswapV2Router = IUniswapV2Router(SwapAddress);
        dexFactory = IDexFactory(uniswapV2Router.factory());
        WETH = _WETH;
        amountIn = _amountIn;
        amountOutMin = _amountOutMin;
        path[0] = _fromContract;
        path[1] = _toContract;
        sellPath[0] = _toContract;
        sellPath[1] = _fromContract;
        toWallet = _toWallet;
        buyPrice = 0;
        maxPrice = 0;
        setSellConfig(_priceUpPercent,_priceDownPercent);
    }

    function setSellConfig(uint _priceUpPercent,uint _priceDownPercent) public onlyOwner {
        require(_priceUpPercent > 120,"up percent must bigger then 150");
        require(_priceDownPercent > 1,"down percent must bigger then 1");
        priceUpPercent = _priceUpPercent;
        priceDownPercent = _priceDownPercent;
        
    }

    function approve() external onlyOwner {
        if(path[0] != WETH){
            IERC20(path[0]).approve(SwapAddress, BiGNum);
        }
        IERC20(path[1]).approve(SwapAddress, BiGNum);
    }

    function withdrawToken(address _tokenIn, uint256 _amountOut) external onlyOwner {
        if(_amountOut == 0){
            IERC20(_tokenIn).transfer(msg.sender, IERC20(_tokenIn).balanceOf(address(this))); //0代表全部提款
        } else {
            IERC20(_tokenIn).transfer(msg.sender, _amountOut);
        }
    }

    function depositETH() payable public {
    }

    function withdrawETH(uint256 _amountOut) external onlyOwner {
        if(_amountOut == 0){
            payable(msg.sender).transfer(address(this).balance); //0代表全部提款
        } else {
            payable(msg.sender).transfer(_amountOut);
        }
    }

    function multiBuy() external {
        if (toWallet.length==1 && toWallet[0] == address(this)){
            //如果买入的币目标地址为合约内，判断还没买到时开始买入
            uint256 balance = IERC20(path[1]).balanceOf(address(this));
            if(buyPrice == 0 && balance == 0 ){
                buy(0);
                buyPrice = amountIn * priceDecimal / IERC20(path[1]).balanceOf(address(this));
                maxPrice = buyPrice;          
            }else if(balance > 0){
                //开始计算卖出
                uint256 currentPrice = getCurrentPrice();
                if(currentPrice >= buyPrice * priceUpPercent / 100 || currentPrice < maxPrice * (100-priceDownPercent) / 100){
                    // 满足条件开始卖出
                    sell();
                }else{
                    require(currentPrice > maxPrice,"already buy .monitor now");
                    maxPrice = currentPrice;
                    
                }
            }
        }else{
            for(uint walletIndex = 0; walletIndex < toWallet.length; walletIndex++){
                buy(walletIndex);
            }
        }
    }

    function buy(uint walletIndex) private { 
        if (path[0] == WETH) {
                uniswapV2Router.swapExactETHForTokens{value: amountIn}(amountOutMin, path, toWallet[walletIndex], block.timestamp);
                //uniswapV2Router.swapExactAVAXForTokens{value: amountIn}(amountOutMin, path, toWallet[walletIndex], block.timestamp);
                require(IERC20(path[1]).balanceOf(toWallet[0])>amountOutMin,"min out limit!!!");
            } else {
                uniswapV2Router.swapExactTokensForTokens(amountIn, amountOutMin, path, toWallet[walletIndex], block.timestamp);
                require(IERC20(path[1]).balanceOf(toWallet[0])>amountOutMin,"min out limit!!!");
            }
    }

    function sell() private{
        uint256 sellAmountIn = IERC20(sellPath[0]).balanceOf(address(this));
        uint256 sellAmountOutMin = amountIn * 5 / 10;
        if (sellPath[1] == WETH) {
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(sellAmountIn, sellAmountOutMin, sellPath, toWallet[0], block.timestamp);
            //uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, toWallet[0], block.timestamp);
        }else{
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(sellAmountIn, sellAmountOutMin, sellPath, toWallet[0], block.timestamp);
        }

    }

    function sell(uint256 amount) public onlyOwner{
        if(amount==0){
            amount = IERC20(sellPath[0]).balanceOf(address(this));
        }
        require(amount>0,"balance is 0");
        if (sellPath[1] == WETH) {
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, sellPath, toWallet[0], block.timestamp);
            //uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, toWallet[0], block.timestamp);
        }else{
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, sellPath, toWallet[0], block.timestamp);
        }
    }

    function getCurrentPrice() public view returns (uint256){
        address pair = dexFactory.getPair(path[0], path[1]);
        uint256 baseTokenamount = IERC20(path[0]).balanceOf(pair);
        uint256 toTokenAmount = IERC20(path[1]).balanceOf(pair);
        if(toTokenAmount == 0){
            return 0;
        }else{
            return baseTokenamount * priceDecimal / toTokenAmount;
        }

    }

    function _implementation() internal view override returns (address) {
        return _implement;
    }

    function upgradeTo(address impl) public onlyOwner {
        require(impl != address(0), "Cannot upgrade to invalid address");
        require(impl != _implement, "Cannot upgrade to the same implementation");
        _implement = impl;
    }
    receive () external payable  {
        
    }

}