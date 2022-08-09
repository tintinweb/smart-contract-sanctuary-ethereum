/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

/**
 * @dev Collection of functions 
 */
abstract contract Context {
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

contract Inter_MLRB is IERC20, Ownable {
    using Address for address;

    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcluded;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => bool) public blocklist;
    mapping(address => bool) public _isMaxWalletExempt;
    mapping(address => bool) public _isTxLimitExempt;

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

    uint256 public constant MAX = ~uint256(0);
    uint256 public _tTotal = 1000000000 * 10**9;
    uint256 public _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _maxTxAmount = _tTotal / 400; // 0.25%
    uint256 public liquidityTrigger;
    uint256 public _tFeeTotal;
    uint256 public _taxFee;
    uint256 public _liquidityFee;
    uint256 public _burnPoolFee;
    uint256 public _marketingFee;
    uint256 public _totalSupply;
    uint256 public maxWalletAmount;
    uint256 public startupToken;
    uint256 public startupETH;

    string public constant _name = "Interchained | Marketing Liquidity Reflections Burn";
    string public constant _symbol = "_MLRB";
    uint8  public constant _decimals = 9;

    address payable public marketingWallet;
    address payable public burnPoolWallet;
    address payable public liquidityWallet;
    address[] public _excluded;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool public launched;
    bool public txLimitEnabled;
    bool public inSwapAndLiquify;
    bool public maxWalletEnabled;
    bool public blocklistEnabled;
    bool public isTradingEnabled;
    bool public isInitialized;
    bool public fundingLiquidity;
    bool public swapAndLiquifyEnabled;

    event SetAutomatedMarketMakerPair(address pair);
    event RemoveAutomatedMarketMakerPair(address pair);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    event SwapAndDistribute(uint256 forMarketing,uint256 forLiquidity,uint256 forBurnPool);
    event SwapETHForTokens(uint256 amountIn, address[] path);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() payable Ownable() {

        startupToken = _maxTxAmount - 1 * 10**9;
        startupETH = 0.15 ether;
        
        excludeFromFee(address(this));
        excludeFromReward(address(this));
        setIsTxLimitExempt(address(this), true);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        setIsTxLimitExempt(address(uniswapV2Router),true);
        setIsTxLimitExempt(address(uniswapV2Pair),true);
        setIsMaxWalletExempt(address(uniswapV2Router),true);
        setIsMaxWalletExempt(address(uniswapV2Pair),true);
        excludeFromFee(address(uniswapV2Router));
        excludeFromFee(address(uniswapV2Pair));
        excludeFromReward(address(uniswapV2Router));
        excludeFromReward(address(uniswapV2Pair));
        setAutomatedMarketMakerPair(address(uniswapV2Pair));

        marketingWallet = payable(0x050134fd4EA6547846EdE4C4Bf46A334B7e87cCD);
        liquidityWallet = payable(0xd166dF9DFB917C3B960673e2F420F928d45C9be1);
        burnPoolWallet = payable(0);

        isInitialized = false;

        buyTax.liquidity = 0;
        buyTax.burnPool = 0;
        buyTax.marketing = 0;
        buyTax.tax = 0;

        sellTax.liquidity = 0;
        sellTax.burnPool = 0;
        sellTax.marketing = 0;
        sellTax.tax = 0;

        _mint(address(this), startupToken, _rTotal, true);
        _mint(_msgSender(), (_tTotal - startupToken), _rTotal, false);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function _mint(address account, uint256 tAmount, uint256 rAmount, bool tOrR) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        unchecked {
                if(tOrR == true){
                    _totalSupply += tAmount;
                }
                _tOwned[account] += tAmount;
                _rOwned[account] += rAmount;
        }
        emit Transfer(address(0), account, tAmount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 rBurnPool, uint256 tBurnPool) internal virtual {
        require(account != address(0), "ERC20: will not burn from the zero address");
        if (_isExcluded[account]) {
            uint256 accountBalance = _tOwned[account];
            require(accountBalance >= tBurnPool, "ERC20: burn amount exceeds balance");
        } else {
            uint256 accountBalance = tokenFromReflection(_rOwned[account]);
            require(accountBalance >= rBurnPool, "ERC20: burn amount exceeds balance");
        }

        unchecked {
            if(_isExcluded[burnPoolWallet]) {
                _tTotal -= tBurnPool;
                _tOwned[address(account)] -= tBurnPool;
                _tOwned[address(burnPoolWallet)] += tBurnPool;
                emit Transfer(address(account), address(burnPoolWallet), tBurnPool);
            } else {
                _tTotal -= rBurnPool;
                _rOwned[address(account)] -= rBurnPool;
                _rOwned[address(burnPoolWallet)] += rBurnPool;
                emit Transfer(address(account), address(burnPoolWallet), rBurnPool);
            }
        }
    }

    function setAutomatedMarketMakerPair(address pair) public onlyOwner {
        automatedMarketMakerPairs[pair] = true;

        emit SetAutomatedMarketMakerPair(pair);
    }
    
    function removeAutomatedMarketMakerPair(address pair) public onlyOwner {
        automatedMarketMakerPairs[pair] = false;
        
        emit RemoveAutomatedMarketMakerPair(pair);
    }
     
    function name() external pure virtual override returns (string memory) {
        return _name;
    }

    function symbol() external pure virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _tTotal;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = (_tTotal * maxTxPercent) / 10**2;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || _isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function checkMaxLimit(address sender, uint256 amount) internal view {
        if(!_isMaxWalletExempt[sender]){
            require(IERC20(address(this)).balanceOf(sender) + amount <= maxWalletAmount, "Max wallet exceeded");
        }
    }
    
    function setIsTxLimitExempt(address holder, bool exempt) public onlyOwner {
        _isTxLimitExempt[holder] = exempt;
    }
    
    function setIsMaxWalletExempt(address holder, bool exempt) public onlyOwner {
        _isMaxWalletExempt[holder] = exempt;
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

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcluded[account]) {
            return _tOwned[account];
        }
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) external virtual override returns (bool) {
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

    function includeInReward(address account) external onlyOwner {
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
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
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
        _rOwned[address(this)] += rLiquidity;
        if (_isExcluded[address(this)])
            _tOwned[address(this)] += tLiquidity;
    }

    function _takeMarketingAndBurnPool(uint256 tMarketing, uint256 tBurnPool) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing*currentRate;
        uint256 rBurnPool = tBurnPool*currentRate;
        _rOwned[address(this)] += (rBurnPool + rMarketing);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] += (tMarketing + tBurnPool);
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

    function updateAllFee(uint256 taxFee, uint256 liquidityFee, uint256 marketingFee, uint256 burnFee) external onlyOwner {
        _taxFee = taxFee;
        _liquidityFee = liquidityFee;
        _marketingFee = marketingFee;
        _burnPoolFee = burnFee;
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

    function launch() public onlyOwner {
        require(launched == false, "Cannot relaunch.");
        require(address(this).balance > 0, "Must have ETH on contract to launch");
        setSwapAndLiquifyEnabled(true);
        manageTrading(true);
        enableBlocklist(true);
        enableMaxWallet(true);
        enableTXLimit(true);
        fundingLiquidity = false;
        if(launched==false){
            launched = true;
        }
        require(launched);
    }

    function manageTrading(bool _onOrOff) public onlyOwner {
        isTradingEnabled = _onOrOff;
    }

    function fundLiquidity() public onlyOwner returns(bool){
        uint256 gasReserves = (address(this).balance * 1000) / 10000;
        uint256 remainder = address(this).balance - gasReserves;
        injectLiquidity(balanceOf(address(this)), remainder, true);
        return true;
    }

    // original reference == LOL @ https://etherscan.io/token/0xf91ac30e9b517f6d57e99446ee44894e6c22c032#code
    // send tokens and ETH for liquidity to contract directly, then call this (not required, can still use Uniswap to add liquidity manually, but this ensures everything is excluded properly and makes for a great stealth launch)
    function initialize() external onlyOwner payable {
        require(!isInitialized, "Contract is already initialized.");
        
        (bool success, ) = address(this).call{ value: msg.value }("");
        require(success);
        maxWalletAmount = _tTotal * 150 / 10000; // 1.5% maxWalletAmount
        _maxTxAmount = _tTotal * 400 / 10000; // 4% _maxTxAmount
        liquidityTrigger = 1000000 * 10**9;
        // run launch() to enable trading / liquidity events
        fundingLiquidity = true;
        swapAndLiquifyEnabled = false;
        isTradingEnabled = false; 
        blocklistEnabled = false;
        maxWalletEnabled = false;
        txLimitEnabled = false;
        isInitialized = true;

        excludeFromReward(address(0));
        excludeFromReward(_msgSender());

        setIsTxLimitExempt(_msgSender(), true);

        setIsMaxWalletExempt(address(0), true);
        setIsMaxWalletExempt(address(this), true);
        setIsMaxWalletExempt(address(marketingWallet), true);
        setIsMaxWalletExempt(address(liquidityWallet), true);

        excludeFromFee(_msgSender());

        _approve(address(this), address(uniswapV2Router), _tTotal);
        _approve(address(this), address(uniswapV2Pair), _tTotal);
        require(isInitialized);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner,address spender,uint256 amount) public virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function enableBlocklist(bool trueOrFalse) public onlyOwner {
        blocklistEnabled = trueOrFalse;
    }

    function enableMaxWallet(bool trueOrFalse) public onlyOwner {
        maxWalletEnabled = trueOrFalse;
    }

    function enableTXLimit(bool trueOrFalse) public onlyOwner {
        txLimitEnabled = trueOrFalse;
    }

    function _transfer(address from,address to,uint256 amount) public virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!isTradingEnabled){
            require(fundingLiquidity == true, "Trading Inactive");
        }
        if (blocklistEnabled) {
            checkBlocklist(from, to);
        }
        if (txLimitEnabled) {
            checkTxLimit(from, amount);
        }
        if (maxWalletEnabled) {
            checkMaxLimit(from, amount);
        }
        bool overMinTokenBalance = IERC20(address(this)).balanceOf(address(this)) >= liquidityTrigger;
        if (isTradingEnabled && overMinTokenBalance && !inSwapAndLiquify && swapAndLiquifyEnabled && address(from) != address(liquidityWallet) && to != address(liquidityWallet)) {
            swapAndDistribute(liquidityTrigger);
        }

        //transfer amount, it will take tax, BurnPool, liquidity fee
        _tokenTransfer(from, to, amount);
    }

    function swapAndDistribute(uint256 contractTokenBalance) internal lockTheSwap {
        uint256 total = buyTax.marketing + sellTax.marketing + buyTax.liquidity + sellTax.liquidity + buyTax.burnPool + sellTax.burnPool;

        uint256 forMarketing = contractTokenBalance * (buyTax.marketing + sellTax.marketing) / total;
        swapAndSendToFee(forMarketing);

        uint256 forLiquidity = contractTokenBalance * (buyTax.liquidity + sellTax.liquidity) / total;
        swapAndLiquify(forLiquidity);

        uint256 forBurnPool = contractTokenBalance - (forLiquidity + forMarketing);
        sendToBurnPool(forBurnPool);     

        emit SwapAndDistribute(forMarketing, forLiquidity, forBurnPool);
    }
    
    function sendToBurnPool(uint256 tBurnPool) internal {
        uint256 currentRate =  _getRate();
        uint256 rBurnPool = tBurnPool * currentRate;
        _burn(_msgSender(),rBurnPool,tBurnPool);
    }

    function swapAndSendToFee(uint256 tokens) internal {
        uint256 initialBalance = (address(this)).balance; 
        swapTokensForETH(tokens);
        uint256 newBalance = (address(this)).balance - initialBalance;
        marketingWallet.transfer(newBalance);
    }

    function swapAndLiquify(uint256 tokens) internal {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(half);

        uint256 newBalance = address(this).balance - initialBalance;

        injectLiquidity(otherHalf, newBalance, false);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function injectLiquidity(uint256 tokenAmount, uint256 ethAmount, bool firstRun) internal {
        if(firstRun == false){
            _approve(address(this), address(uniswapV2Router), tokenAmount);
        }
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount,0,0,liquidityWallet,block.timestamp);
    }

    function _tokenTransfer(address sender,address recipient,uint256 amount) private {
        if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]) {
            if (automatedMarketMakerPairs[sender] == true) {
                setBuyTax();
            } else if (automatedMarketMakerPairs[recipient] == true) {
                setSellTax();
            }
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
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _takeMarketingAndBurnPool(calculateMarketingFee(tAmount),calculateBurnPoolFee(tAmount));
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender,address recipient,uint256 tAmount) private {
        (uint256 rAmount,uint256 rTransferAmount,uint256 rFee,uint256 tTransferAmount,uint256 tFee,uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _takeMarketingAndBurnPool(calculateMarketingFee(tAmount),calculateBurnPoolFee(tAmount));
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender,address recipient,uint256 tAmount) private {
        (uint256 rAmount,uint256 rTransferAmount,uint256 rFee,uint256 tTransferAmount,uint256 tFee,uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _takeMarketingAndBurnPool(calculateMarketingFee(tAmount),calculateBurnPoolFee(tAmount));
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender,address recipient,uint256 tAmount) private {
        (uint256 rAmount,uint256 rTransferAmount,uint256 rFee,uint256 tTransferAmount,uint256 tFee,uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
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

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function setLiquidityTriggerInTokens(uint256 amount) external onlyOwner {
        liquidityTrigger = amount;
    }

    function updateLiquidityWallet(address payable newLiquidityWallet) external onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "The liquidity wallet is already this address");
        liquidityWallet = payable(newLiquidityWallet);
    }   

    function updateMarketingWallet(address payable newWallet) external onlyOwner {
        marketingWallet = payable(newWallet);
    } 
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * And sets the liquidity wallet. Can only be called by the current owner. 
     */
    function _transferOwnership(address payable newOwner) public virtual onlyOwner returns(bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        transferOwnership(newOwner);
        return true;
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
    
    // withdraw ETH if stuck before launch
    function withdrawStuckETH() external onlyOwner {
        require(!isTradingEnabled, "Can only withdraw if trading hasn't started");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

}