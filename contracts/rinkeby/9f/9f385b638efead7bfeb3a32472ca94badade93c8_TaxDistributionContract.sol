/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: contracts/taxDistributionContract.sol


pragma solidity 0.8.9;



interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    // function setFeeTo(address) external;
    // function setFeeToSetter(address) external;
}



interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}



interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}



interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract TaxDistributionContract is  Ownable {
    uint256 public investorAmountThreshold = 70000000000000000000;
    uint256 public amountDistributedToInvestors;
    uint256 initialInvestorPercentage = 5000;
    uint256 investorPercentage = 2500;
    uint256 public priceImpactMax  = 200;
    uint256 public slippage =10000;
    uint256 public epoch = 28800;
    uint256 public lastDistributedTime;
    address  payable public  investorWallet = payable(0x50Ca1fde29D62292a112A72671E14a5d4f05580f);
    address  payable public teamWallet = payable(0x50Ca1fde29D62292a112A72671E14a5d4f05580f);
    address public TGKToken;
    uint256 public amountDistributedToTeam;
    bool public reverse;
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public pairContract  ;
    

    // events
    event InvestorAmountThresholdUpdated(uint256 amount);
    event InitialInvestorPercentageUpdated(uint256 percentage);
    event InvestorPercentageUpdated(uint256 percentage);
    event PriceImpactMaxUpdated(uint256 max);
    event InvestorWalletUpdated(address wallet);
    event TeamWalletUpdated(address wallet);
    event TokenContractUpdated(address token);
    event RouterUpdated(address router);
    event PairUpdated(address pair);
    event SlippageUpdated(uint256 slippage);
    event EpochUpdated(uint256 epoch);
    event ReverseUpdated(bool reverse);

    constructor(address token, address pair) {

         TGKToken = token;
         pairContract = IUniswapV2Pair(pair);
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        if(pairContract.token1() == TGKToken){
           reverse = true;
        }
        uniswapV2Router = _uniswapV2Router;
        


    }

    function setInvestorThresholdAmount(uint256 amount) external onlyOwner{
        investorAmountThreshold = amount;
        emit InvestorAmountThresholdUpdated(amount);
    }

    function setInvestorInitialPercentage(uint256 percentage) external onlyOwner{
        initialInvestorPercentage = percentage;
        emit InitialInvestorPercentageUpdated(percentage);
    }

    function setInvestorPercentage(uint256 percentage) external onlyOwner{
        investorPercentage = percentage;
        emit InvestorPercentageUpdated(percentage);
    }

    function setInvestorWalletAddress(address wallet) external onlyOwner{
        investorWallet = payable(wallet);
        emit InvestorWalletUpdated(wallet);
    }

    function setTeamWalletAddress(address wallet) external onlyOwner{
        investorWallet = payable(wallet);
        emit TeamWalletUpdated(wallet);
    }

    function setTGKAddress(address token) external onlyOwner{
        TGKToken = token;
        emit TokenContractUpdated(token);
    }

    function setRouterAddress(address router) external onlyOwner{
        uniswapV2Router = IUniswapV2Router02(router);
        emit RouterUpdated(router);
    }

    function setPairAddress(address pair) external onlyOwner{
        pairContract = IUniswapV2Pair(pair);
        emit PairUpdated(pair);
    }

    function setPriceImpactMx(uint256 max) external onlyOwner{
        priceImpactMax = max;
        emit PriceImpactMaxUpdated(max);
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        slippage = slippage;
        emit SlippageUpdated(_slippage);
    }

    function setReverse(bool rev) external onlyOwner{
        reverse = rev;
        emit ReverseUpdated(rev);
    }

    function updateEpoch(uint256 _epoch) external onlyOwner{
        epoch = _epoch;
        emit EpochUpdated(_epoch);
    }

    function calcPairSwap(uint256 amountA) public view returns(uint256 priceImpact) {
        if(reverse == true){
        (uint256 reserveA, uint256 reserveB,) = pairContract.getReserves();
        uint256 amountB =  uniswapV2Router.getAmountOut(amountA, reserveB, reserveA);
        priceImpact = (reserveA-(reserveA-(amountB)))*(10000) / reserveA;
        }
        else{
        (uint256 reserveA, uint256 reserveB,) = pairContract.getReserves();
        uint256 amountB =  uniswapV2Router.getAmountOut(amountA, reserveA, reserveB);
        priceImpact =  (reserveB-(reserveB-(amountB)))*(10000) / reserveB;

        }
        return( priceImpact);    
    }

    function distributeTax(uint256 amount) external {
        require(block.timestamp >= epoch + lastDistributedTime,"Epoch Time not completed");
        lastDistributedTime = block.timestamp;
        require(calcPairSwap(amount)<=priceImpactMax,"Price Impact Exceeded");
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(amount);
        uint256 newBalance = address(this).balance-(initialBalance);
        if(amountDistributedToInvestors <= investorAmountThreshold){
         uint256 investorAmount = (newBalance*initialInvestorPercentage)/10000;
         investorWallet.transfer(investorAmount);
         amountDistributedToInvestors = amountDistributedToInvestors + investorAmount;
         uint256 amountLeft = newBalance-investorAmount;
         teamWallet.transfer(amountLeft);
         amountDistributedToTeam = amountDistributedToTeam + amountLeft;
        }
        else{

         uint256 investorAmount = (newBalance*investorPercentage)/10000;
         investorWallet.transfer(investorAmount);
         amountDistributedToInvestors = amountDistributedToInvestors + investorAmount;
         uint256 amountLeft = newBalance-investorAmount;
         teamWallet.transfer(amountLeft);
         amountDistributedToTeam = amountDistributedToTeam + amountLeft;
        }

    }


    function swapTokensForEth(uint256 tokenAmount) private {
       
        address[] memory path = new address[](2);
        path[0] = TGKToken;
        path[1] = uniswapV2Router.WETH();
      
        IERC20(TGKToken).approve(address(uniswapV2Router), 2**256 - 1);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            tokenAmount - (tokenAmount*slippage/10000), 
            path,
            address(this),
            block.timestamp + 1000
        );
    }
    
    receive() external payable {}

    function withdrawTokens(IERC20 token, address wallet) external onlyOwner{
         uint256 balanceOfContract = token.balanceOf(address(this));
        token.transfer(wallet,balanceOfContract);
    }
    
    function withdrawFunds(address wallet) external onlyOwner{
        uint256 balanceOfContract = address(this).balance;
        payable(wallet).transfer(balanceOfContract);
    }
}