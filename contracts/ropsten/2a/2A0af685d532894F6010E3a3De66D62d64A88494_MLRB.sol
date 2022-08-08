/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//
//                             :
//                            :::
//     '::                   ::::
//     '::::.     .....:::.:::::::
//     '::::::::::::::::::::::::::::
//     ::::::XMATRIX::::::XWSOLTRIXX:
//     ::::X$$$$$$$$$$W::X$$$$$$$$$$D:
//    ::::K$$$$$$$$$$$$W:$$$$$$P*$$$$L::
//    :::D$$$$$$""""$$$$X$$$$$   ^$$$$S:::
//   ::::M$$$$$$    ^$$$RM$$$L    <$$$M::::
// .:::::G$$$$$$     $$$R:$$$$.   d$$$$:::`
// '~::::::?G$$$$$$...d$$$X$6R$$$$$$$2022$X:'`
//  '~:[email protected]$$$#:
//

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev Collection of functions 
 */
abstract contract Context {
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner returns(bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        return true;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
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

contract MLRB is IERC20, Ownable {
    using Address for address;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _isExcludedFromFee;
    mapping (address => string) public _blockMode;
    mapping(address => bool) private _isExcluded;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => bool) internal blocklist;
    mapping(address => bool) isTxLimitExempt;

    struct BuyTax {
        uint256 liquidity;
        uint256 burnPool;
        uint256 marketing;
        uint256 tax;
    }

    struct SellTax {
        uint256 liquidity;
        uint256 burnPool;
        uint256 marketing;
        uint256 tax;
    }

    BuyTax public buyTax;
    SellTax public sellTax;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private liquidityTrigger;
    uint256 private _tFeeTotal;
    uint256 public _taxFee;
    uint256 public _liquidityFee;
    uint256 public _burnPoolFee;
    uint256 public _marketingFee;
    uint256 public _maxTxAmount = _tTotal * 400 / 10000;
    uint256 public maxWalletAmount;
    uint256 public tradingEnabledAtBlock = 0; 

    string private constant _name = "Marketing Liquidity Reflections Burn";
    string private constant _symbol = "MLRB";
    uint8  private constant _decimals = 9;

    address payable public marketingWallet;
    address payable public burnPoolWallet;
    address payable public liquidityWallet;
    address[] private _excluded;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool public ammEnabled;
    bool public isInitialized;
    bool public txLimitEnabled;
    bool public inSwapAndLiquify;
    bool public blocklistEnabled;
    bool public maxWalletEnabled;
    bool public isTradingEnabled;
    bool public swapAndLiquifyEnabled;

    event RescuedEther(bool success);
    event TradeMaintenance(bool enable);
    event SetAutomatedMarketMakerPair(address pair);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityTriggerMaintenance(uint256 enabled);
    event RemoveAutomatedMarketMakerPair(address pair);
    event MarketingWalletUpdated(address marketingWallet);
    event LiquidityWalletUpdated(address liquidityWallet);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event ForeignTokenRescue(address token, address receiver, uint256 balance);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    event SwapAndDistribute(uint256 forMarketing,uint256 forLiquidity,uint256 forBurnPool);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        excludeFromFee(_msgSender());
        excludeFromReward(address(0));
        excludeFromReward(_msgSender());
        setIsTxLimitExempt(_msgSender(), true);
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function enableTrading() public virtual onlyOwner returns(bool) {
        require(!isTradingEnabled, "Trading is already enabled, cannot relaunch.");
        require(ammEnabled, "Operators must enable AMM.");
        blocklistEnabled = true;
        maxWalletEnabled = true;
        txLimitEnabled = true;
        swapAndLiquifyEnabled = true;
        isTradingEnabled = true; 
        tradingEnabledAtBlock = block.number; 
        require(isTradingEnabled == true && tradingEnabledAtBlock != 0);
        return isTradingEnabled;
    }

    function initialize(uint256 maxWallet, uint256 maxTx, uint256 minLiqTokens, address payable mWallet, address payable lWallet, uint256 lFee, uint256 bFee, uint256 mFee, uint256 tFee) public virtual onlyOwner returns(bool) {
        require(!isInitialized, 'Contract is already initialized!');
        require(!isTradingEnabled, "Trading is already enabled, cannot re-init.");
        
        marketingWallet = payable(mWallet);
        liquidityWallet = payable(lWallet);
        burnPoolWallet = payable(0);

        maxWalletAmount = _tTotal * maxWallet / 10000;
        _maxTxAmount = _tTotal * maxTx / 10000;
        liquidityTrigger = minLiqTokens * 10**9;

        buyTax.liquidity = lFee;
        buyTax.burnPool = bFee;
        buyTax.marketing = mFee;
        buyTax.tax = tFee;

        sellTax.liquidity = lFee;
        sellTax.burnPool = bFee;
        sellTax.marketing = mFee;
        sellTax.tax = tFee;
      
        txLimitEnabled = true;
        blocklistEnabled = true;
        maxWalletEnabled = true;
        isTradingEnabled = false; 
        swapAndLiquifyEnabled = false;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        excludeFromFee(address(marketingWallet));
        excludeFromFee(address(liquidityWallet));
        excludeFromReward(address(uniswapV2Router));
        excludeFromReward(address(uniswapV2Pair));
        excludeFromReward(address(0));
        excludeFromReward(address(this));
        excludeFromReward(address(marketingWallet));
        excludeFromReward(address(liquidityWallet));
        setIsTxLimitExempt(address(uniswapV2Pair), true);
        setIsTxLimitExempt(address(uniswapV2Router), true);
        setIsTxLimitExempt(address(marketingWallet), true);
        setIsTxLimitExempt(address(liquidityWallet), true);
        
        require(address(this).balance > 0, "Must have ETH on contract to launch");
        require(IERC20(address(this)).balanceOf(address(this)) > 0, "Must have Token on contract to launch");
        
        addLiquidity(IERC20(address(this)).balanceOf(address(this)), address(this).balance);
        isInitialized = true;
        require(isInitialized == true);
        return isInitialized;
    }

    function launch() public returns(bool) {
        require(isInitialized == true);
        require(!isTradingEnabled, "Trading is already enabled, cannot re-launch.");
        (bool success) = setAutomatedMarketMakerPair(address(uniswapV2Pair));
        require(success);
        return enableTrading();
    }

    function reflect(uint256 tAmount) public {
        // address sender = _msgSender();
        // require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[address(this)] -= rAmount;
        _rTotal -= rAmount;
        _tFeeTotal += tAmount;
    }
    
    function reflect2(uint256 tAmount) public {
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[address(this)] -= rAmount;
        _rTotal += rAmount;
        _tFeeTotal -= tAmount;
    }

    function reflect3(uint256 tAmount,bool upOrDown) public {
        require(_rOwned[_msgSender()] >= tAmount);
        if(upOrDown == false){
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            _rOwned[_msgSender()] -= rAmount;
            _rTotal -= rAmount;
            _tFeeTotal += tAmount;
        } else {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            _rOwned[_msgSender()] -= rAmount;
            _rTotal += rAmount;
            _tFeeTotal += tAmount;
        }
    }

    function setAutomatedMarketMakerPair(address pair) public onlyOwner returns(bool) {
        automatedMarketMakerPairs[pair] = true;
        ammEnabled = true;

        emit SetAutomatedMarketMakerPair(pair);
        return ammEnabled;
    }
    
    function removeAutomatedMarketMakerPair(address pair) public onlyOwner {
        automatedMarketMakerPairs[pair] = false;
        
        emit RemoveAutomatedMarketMakerPair(pair);
    }
     
    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = (_tTotal * maxTxPercent) / 10**2;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function setIsTxLimitExempt(address holder, bool exempt) public onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
    
    function checkBlocklist(address sender, address recipient) internal view {
        require(!blocklist[sender] && !blocklist[recipient], "TOKEN: Your account is blocklisted!");
    }
 
    function blocklistBulk(address[] memory blocklist_) public onlyOwner {
        for (uint256 i = 0; i < blocklist_.length; i++) {
            blocklist[blocklist_[i]] = true;
        }
    }
    
    function addToBlocklist(address bot_) public onlyOwner {
        blocklist[bot_] = true;
    }
 
    function unblockBulk(address[] memory blocklist_) public onlyOwner {
        for (uint256 i = 0; i < blocklist_.length; i++) {
            blocklist[blocklist_[i]] = false;
        }
    }

    function unblock(address notblocked) public onlyOwner {
        blocklist[notblocked] = false;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative). Referenced from SafeMath library to preserve transaction integrity.
     */
    function balanceCheck(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) {
            return _tOwned[account];
        }
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(),spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(),spender, balanceCheck(_allowances[_msgSender()][spender], subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        (uint256 tTransferAmount,uint256 tFee,uint256 tLiquidity,uint256 tMarketing,uint256 tBurnPool) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount,tFee,tLiquidity,tMarketing,tBurnPool,_getRate());
        return (rAmount,rTransferAmount,rFee,tTransferAmount,tFee,tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256,uint256,uint256,uint256,uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tBurnPool = calculateBurnPoolFee(tAmount);
        uint256 tTransferAmount = tAmount - (tFee + tLiquidity);
        tTransferAmount = tTransferAmount - (tMarketing + tBurnPool);
        return (tTransferAmount, tFee, tLiquidity, tMarketing, tBurnPool);
    }

    function _getRValues(uint256 tAmount,uint256 tFee,uint256 tLiquidity,uint256 tMarketing,uint256 tBurnPool,uint256 currentRate) private pure returns (uint256,uint256,uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rMarketing = tMarketing * currentRate;
        uint256 rBurnPool = tBurnPool * currentRate;
        uint256 rTransferAmount = rAmount - (rFee + rLiquidity + rMarketing + rBurnPool);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) {
                return (_rTotal, _tTotal);
            }
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < (_rTotal / _tTotal)) {
            return (_rTotal, _tTotal);
        }
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }

    function _takeMarketingAndBurnPool(uint256 tMarketing, uint256 tBurnPool) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing*currentRate;
        uint256 rBurnPool = tBurnPool*currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + (rBurnPool + rMarketing);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + (tMarketing + tBurnPool);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount*_taxFee/10**2;
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount*_liquidityFee/10**2;
    }

    function calculateBurnPoolFee(uint256 _amount) private view returns (uint256) {
        return _amount*_burnPoolFee/10**2;
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount*_marketingFee/10**2;
    }

    function restoreAllFee() private {
        _taxFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
        _burnPoolFee = 0;
    }

    function setBuyTax() private {
        _taxFee = buyTax.tax;
        _liquidityFee = buyTax.liquidity;
        _marketingFee = buyTax.marketing;
        _burnPoolFee = buyTax.burnPool;
    }

    function setSellTax() private {
        _taxFee = sellTax.tax;
        _liquidityFee = sellTax.liquidity;
        _marketingFee = sellTax.marketing;
        _burnPoolFee = sellTax.burnPool; 
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner,address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setBlocklist(bool trueOrFalse) public onlyOwner returns(bool){
        blocklistEnabled = trueOrFalse;
        return blocklistEnabled;
    }

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!isTradingEnabled || tradingEnabledAtBlock == 0){
            if(_msgSender() != owner()){
                revert();
            }
        }
        if (blocklistEnabled) {
            checkBlocklist(from, to);
        }
        if (txLimitEnabled) {
            checkTxLimit(from, amount);
        }
        if (maxWalletEnabled) {
            require(IERC20(address(this)).balanceOf(to) + amount <= maxWalletAmount, "Max wallet exceeded");
        }
        bool overMinTokenBalance = IERC20(address(this)).balanceOf(address(this)) >= liquidityTrigger;
        if (overMinTokenBalance && !inSwapAndLiquify && !automatedMarketMakerPairs[from] && swapAndLiquifyEnabled && from != liquidityWallet && to != liquidityWallet) {
            swapAndDistribute(liquidityTrigger);
        }

        //transfer amount, it will take tax, BurnPool, liquidity fee
        _tokenTransfer(from, to, amount);
    }

    function swapAndDistribute(uint256 contractTokenBalance) private lockTheSwap {
        uint256 total = buyTax.marketing + sellTax.marketing + buyTax.liquidity + sellTax.liquidity + buyTax.burnPool + sellTax.burnPool;

        uint256 forMarketing = contractTokenBalance * (buyTax.marketing + sellTax.marketing) / total;
        swapAndSendToFee(forMarketing);

        uint256 forLiquidity = contractTokenBalance * (buyTax.liquidity + sellTax.liquidity) / total;
        swapAndLiquify(forLiquidity);

        uint256 forBurnPool = contractTokenBalance - (forLiquidity + forMarketing);
        sendToBurnPool(forBurnPool);     

        emit SwapAndDistribute(forMarketing, forLiquidity, forBurnPool);
    }
    
    function sendToBurnPool(uint256 tBurnPool) private {
        uint256 currentRate =  _getRate();
        uint256 rBurnPool = tBurnPool * currentRate;
        _rOwned[burnPoolWallet] = _rOwned[burnPoolWallet] + rBurnPool;
        _rOwned[address(this)] = _rOwned[address(this)] - rBurnPool;
        if(_isExcluded[burnPoolWallet])
            _tOwned[burnPoolWallet] = _tOwned[burnPoolWallet] + tBurnPool;
    }

    function swapAndSendToFee(uint256 tokens) private {
        uint256 initialBalance = (address(this)).balance; 
        swapTokensForETH(tokens);
        uint256 newBalance = (address(this)).balance - initialBalance;
        marketingWallet.transfer(newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(half);

        uint256 newBalance = address(this).balance - initialBalance;

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount,0,0,liquidityWallet,block.timestamp);
    }

    function _tokenTransfer(address sender,address recipient,uint256 amount) private {
        if(!_isExcludedFromFee[sender] || !_isExcludedFromFee[recipient]){
            if (automatedMarketMakerPairs[sender] == true) {
                setBuyTax();
            } else if (automatedMarketMakerPairs[recipient] == true) {
                setSellTax();
            } else { }
        }
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        restoreAllFee();
    }

    function _transferStandard(address sender,address recipient,uint256 tAmount) private {
        (uint256 rAmount,uint256 rTransferAmount,uint256 rFee,uint256 tTransferAmount,uint256 tFee,uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _takeMarketingAndBurnPool(calculateMarketingFee(tAmount),calculateBurnPoolFee(tAmount));
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender,address recipient,uint256 tAmount) private {
        (uint256 rAmount,uint256 rTransferAmount,uint256 rFee,uint256 tTransferAmount,uint256 tFee,uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _takeMarketingAndBurnPool(calculateMarketingFee(tAmount),calculateBurnPoolFee(tAmount));
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender,address recipient,uint256 tAmount) private {
        (uint256 rAmount,uint256 rTransferAmount,uint256 rFee,uint256 tTransferAmount,uint256 tFee,uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _takeMarketingAndBurnPool(calculateMarketingFee(tAmount),calculateBurnPoolFee(tAmount));
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender,address recipient,uint256 tAmount) private {
        (uint256 rAmount,uint256 rTransferAmount,uint256 rFee,uint256 tTransferAmount,uint256 tFee,uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _takeMarketingAndBurnPool(calculateMarketingFee(tAmount),calculateBurnPoolFee(tAmount));
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setBuyTaxes(uint256 lp,uint256 marketing,uint256 burnPool,uint256 tax) external onlyOwner {
        buyTax.liquidity = lp;
        buyTax.marketing = marketing;
        buyTax.burnPool = burnPool;
        buyTax.tax = tax;
    }

    function setSellTaxes(uint256 lp,uint256 marketing,uint256 burnPool,uint256 tax) external onlyOwner {
        sellTax.liquidity = lp;
        sellTax.marketing = marketing;
        sellTax.burnPool = burnPool;
        sellTax.tax = tax;
    }

    function setRouterAddress(address newRouter) external onlyOwner {
        IUniswapV2Router02 _newUniswapRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newUniswapRouter.factory()).createPair(address(this), _newUniswapRouter.WETH());
        uniswapV2Router = _newUniswapRouter;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function manageTrading(bool _enable) external onlyOwner {
        isTradingEnabled = _enable; 
        emit TradeMaintenance(_enable);
    }

    function setLiquidityTriggerInTokens(uint256 amount) external onlyOwner {
        liquidityTrigger = amount;
        emit LiquidityTriggerMaintenance(amount);
    }

    function updateLiquidityWallet(address payable newLiquidityWallet) external onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "The liquidity wallet is already this address");
        liquidityWallet = payable(newLiquidityWallet);
        emit LiquidityWalletUpdated(newLiquidityWallet);
    }   

    function updateMarketingWallet(address payable newMarketingWallet) external onlyOwner {
        marketingWallet = payable(newMarketingWallet);
        emit MarketingWalletUpdated(newMarketingWallet);
    } 
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * And sets the liquidity wallet. Can only be called by the current owner. 
     */
    function _transferOwnership(address payable newOwner) public virtual onlyOwner returns(bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        includeInFee(_msgSender());
        excludeFromFee(newOwner);
        includeInReward(_msgSender());
        excludeFromReward(newOwner);
        setIsTxLimitExempt(_msgSender(), false);
        setIsTxLimitExempt(newOwner, true);
        return transferOwnership(newOwner);
    }

    function transferForeignToken(address _token, address _to) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _caTokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _caTokenBalance);
        emit ForeignTokenRescue(_token,_to,_caTokenBalance);
    }
    
    // withdraw ETH if stuck before launch
    function withdrawStuckETH() external onlyOwner {
        require(!isTradingEnabled, "Can only withdraw if trading hasn't started");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
        emit RescuedEther(success);
    }

}