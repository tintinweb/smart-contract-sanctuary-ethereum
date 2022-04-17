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

pragma solidity >=0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.8.0;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./StrategyStandard.sol";
import "../interfaces/IUniswapV2Router02.sol";


/**
* @title ETHHODLStrategy
* @author Caron Case ([email protected])
    contract to standardize what strategies do 
*/
contract ETHHODLStrategy is StrategyStandard{
    // for testing
    address public eth;

    IUniswapV2Router02 public dex;
    uint constant secondsInYear = 31540000;

    int priceUSD = 2;
    int96 apr = 12;

    uint constant SLIPPAGE = 5;                     // making this owner controlled is not a bad idea
    uint constant ONE_HUNDRED_PERCENT = 100;
    
    constructor(address _swaps, address _treasury, address _oracle, address _dex) StrategyStandard(_treasury, _oracle){
        swaps = ISwaps(_swaps);
        dex = IUniswapV2Router02(_dex);
        IERC20(stablecoin).approve(_dex,2**256-1);
        transferOwnership(_treasury);
        eth = dex.WETH();
    }

    receive() payable external{

    }

    // TEST only
    function updatePriceE18(int _new) external{
        priceUSD = _new;
    }

    function fund(uint256 _amountInvestment) public override onlyOwner{
        super.fund(_amountInvestment);
        address[] memory path = new address[](2);
        path[0] = stablecoin;
        path[1] = eth;

        uint minOut = _getMinOut(_amountInvestment);
        dex.swapExactTokensForETH(_amountInvestment,minOut,path,address(this),block.timestamp + 30);
    }

    function removeFunds(uint256 _amountToRemove, address _receiver) public override onlyOwner{
        require(_amountToRemove <= address(this).balance, "Not enough eth in strategy");
        super.removeFunds(_amountToRemove, _receiver);

        address[] memory path = new address[](2);
        path[0] = eth;
        path[1] = stablecoin;

        uint minOut = _getMinOut(_amountToRemove);
        dex.swapExactETHForTokens{value: _amountToRemove}(minOut, path, _receiver, block.timestamp + 30);
    }

    function getPriceUnderlyingUSD(uint _underlyingAm) public view override returns(int){
        (int price, uint8 decimals) = oracle.priceOf(eth);
        return((int(_underlyingAm) * price) / int(10**decimals));
    }

    function getAmountOfUnderlyingForUSD(int _amount) public view override returns(int){
        (int price, uint8 decimals) = oracle.priceOf(eth);
        return((int(10**decimals) * (int(_amount)) / price));
    }

    function getFlowRate(uint _amountUnderlying) public view returns(int96){
        return (int96(getPriceUnderlyingUSD(_amountUnderlying/secondsInYear)) * apr) / 100;
    }

    /**
    * @dev override just handles swaps logic. Verifying underlying available is done in parent
     */
    function _issueSwap(address _issueTo, uint _amountUnderlying) internal override{
        swaps.newSwap(treasury,_issueTo, getFlowRate(_amountUnderlying),_amountUnderlying);
    }

    function _getMinOut(uint _amountIn) internal pure returns(uint minOut){
        minOut = (_amountIn * (ONE_HUNDRED_PERCENT - SLIPPAGE)) / ONE_HUNDRED_PERCENT;
    }


}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITreasury{
    function stablecoin() external returns(IERC20);
}

interface IOracle{
    function priceOf(address) external view returns(int,uint8);
}

interface ISwaps{
    function newSwap(address _receiver, address _payer, int96 _requiredFlowRate, uint _amountUnderlying) external;
}

/**
* @title StrategyStandard
* @author Caron Case ([email protected])
    contract to standardize what strategies do 
*/
abstract contract StrategyStandard is Ownable{
    address public immutable treasury;
    address internal stablecoin;
    uint256 public underlyingInvested;
    uint256 public underlyingExposedToSwaps;
    IOracle public oracle;
    ISwaps public swaps;

    constructor(address _treasury, address _oracle) Ownable(){
        treasury = _treasury;
        stablecoin = address(ITreasury(_treasury).stablecoin());
        oracle = IOracle(_oracle);
    }

    modifier onlySwaps(){
        require(msg.sender == address(swaps), "StrategyStandard: Only Swaps contract can call this function");
        _;
    }

    function getPriceUnderlyingUSD(uint _underlyingAm) external view virtual returns(int){
        (int price, uint8 decimals) = oracle.priceOf(stablecoin);
        return((int(_underlyingAm) * price) / int(10**decimals));
    }

    function getAmountOfUnderlyingForUSD(int _amount) public view virtual returns(int){
        (int price, uint8 decimals) = oracle.priceOf(stablecoin);
        return((int(10**decimals) * (int(_amount)) / price));
    }


    /**
    * @dev fund function to provide funds to the strategy
    * override to provide with the actual logic of the investment strategy
     */
    function fund(uint256 _amountInvestment) public virtual onlyOwner{
        underlyingInvested += _amountInvestment;
        IERC20(stablecoin).transferFrom(treasury, address(this), _amountInvestment);
    }   

    /**
    * @dev function for owner (treasury) to remove funds 
     */
    function removeFunds(uint256 _amountToRemove, address _receiver) public virtual onlyOwner{
        require(underlyingInvested > underlyingExposedToSwaps + _amountToRemove, "There's not enough free assets in this strategy to remove this amount"); 
    }

    function closeSwap(uint256 _amountToRemove) public virtual onlySwaps{
        underlyingExposedToSwaps -= _amountToRemove;
    }

    /**
    * @dev function to buy swap on the strategy. Can only be done if it's free
     */
    function buySwap(uint256 _amountUnderlying) public virtual{
        require(underlyingInvested > underlyingExposedToSwaps + _amountUnderlying, "There's not enough free assets in this strategy to invest this amount"); 
        underlyingExposedToSwaps += _amountUnderlying;
        _issueSwap(msg.sender, _amountUnderlying);
    }
    

    /**
    * @dev handles logic of issuing swap
     */
    function _issueSwap(address _issueTo, uint _amountUnderlying) internal virtual{
        // issue NFT with supperfuild superapp
        // and send other end of NFT to treasury
    }

}