/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.8.6;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

contract Ownable is Context {
    address private _owner;

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

    function setOwner(address _newOwner) internal {
        _owner = _newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

  
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

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

contract TST is Context, IERC20, Ownable {
    using Address for address;
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping (address => bool) private _isExcludedFromFee;

    // WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    // WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address constant WBNB                            = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DEAD                            = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO                            = 0x0000000000000000000000000000000000000000;
    address public adminZero                         = 0x08Ef4E21723a8d6FEcE8006fB02b6Fe34b64031a; 
    address public adminOne                          = 0x08Ef4E21723a8d6FEcE8006fB02b6Fe34b64031a;

    // MAIN WALLET ADDRESSES
    address private MKT                              = 0x08Ef4E21723a8d6FEcE8006fB02b6Fe34b64031a;
    address private TEAM                             = 0x08Ef4E21723a8d6FEcE8006fB02b6Fe34b64031a;
    address private PROJECT_A                        = 0x08Ef4E21723a8d6FEcE8006fB02b6Fe34b64031a;
    address private PROJECT_B                        = 0x08Ef4E21723a8d6FEcE8006fB02b6Fe34b64031a;
    address private PROJECT_C                        = 0x08Ef4E21723a8d6FEcE8006fB02b6Fe34b64031a;
    address private PRESALE_ADDRESS                  = 0x08Ef4E21723a8d6FEcE8006fB02b6Fe34b64031a;

    // TOKEN GLOBAL VARIABLES
    string constant _name                            = "REKTETH";
    string constant _symbol                          = "COPYTRADERS";
    uint8  constant _decimals                        = 18;
    uint256 _totalSupply                             = 10000000 * 10 ** _decimals;

 
    uint256 public  _maxBuyAmount                    = 10000000 * 10 ** _decimals;
    bool    public  maxBuyEnabled                    = false;

    // INITIAL MAX WALLET HOLDING SET TO 100%
    uint256 public _maxWalletToken                   = _totalSupply;

    // MAPPINGS
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _allowances;
    mapping (address => bool) public                   isFeeExempt;
    mapping (address => bool) public                   isTxLimitExempt;
    mapping (address => bool) public                   isTimelockExempt;
    mapping (address => bool) public                   liquidityAddress;
    mapping (address => bool) private                  _auth;
    // TRANSFER FEE
    uint256 constant INITIAL_TRANSFER_TAX_RATE       = 6;
    uint256 public   transferTaxRate                 = 6;
    bool    public   takeFeeIfNotLiquidity           = true;

    // SELL FEE & DISTRIBUTION SETTINGS
    uint256 public liquidityFee                       = 3;
    uint256 public marketingFee                       = 7;
    uint256 public projectFee                         = 2;
    uint256 public burnFee                            = 0;
    uint256 public teamFee                            = 0;
    // SETS UP TOTAL FEE
    uint256 public totalFee = (liquidityFee + marketingFee + projectFee + teamFee + burnFee);

    // FEE DENOMINATOR CANNOT BE CHANGED.
    uint256 public constant feeDenominator            = 100;
    // SET UP FEE RECEIVERS
    address public burnFeeReceiver                    = DEAD;
    address public projectFeeReceiverA                = PROJECT_A;
    address public projectFeeReceiverB                = PROJECT_B;
    address public projectFeeReceiverC                = PROJECT_C;
    address public teamFeeReceiver                    = TEAM;
    address public autoLiquidityReceiver              = MKT;
    address public marketingFeeReceiver               = MKT;
    
    bool private swapping;
    address public lastSell                           = ZERO;


    // SWITCH TRADING
    bool    public  tradingOpen                       = false;
    uint256 private launchedAt                        = 0;

    // MULTI-SIGNATURE GLOBAL VARIABLES
    uint256 public multiSignatureID                   = 0;
    uint256 public multiSignatureDeadline             = 0;
    uint256 public multiSignatureInterval             = 0;
    address public multiSignatureAddress              = ZERO;

    // THE 4 DRAGONS ANTI-BOT SYSTEM
    event Buy (address indexed from, address indexed to, uint256 value);
    event Sell(address indexed from, address indexed to, uint256 value);

    mapping (address => uint256) public                 _caught;
    mapping (address => uint256) public                 _bought;
    mapping (uint256 => address) public                 _soulID;
    uint256 private foolQuantity                      = _maxBuyAmount / 100;
    uint256 public  totalCaptured                     = 0;
    uint256 private oldGas                            = 0; 
    uint256 private oldGwei                           = 0; 
    uint256 private oldTimestamp                      = 0; 
    uint256 private youShallNotPass                   = 1666878239; 
    uint256 private launchMultiplier                  = 2; 
    uint256 private maxGasLeft                        = 1400000; 
    uint256 private maxGwei                           = 7 gwei;
    uint256 private maxSellGwei                       = 6 gwei; 
    uint256 private dragonFee                         = 2700;
    address private nextOne                           = ZERO;
    address private lastOne                           = ZERO;
    address private oldRecipient                      = ZERO;
    bool    private queueEnabled                      = false;
    bool    private alternateDragon                   = false;
    string  private foolMessage                       = "Do not try to fool the dragons";
    string  private deadDragon                        = "!Dragons";
    
    // MULTI-SIGNATURE TEMPORARY VARIABLES
    uint256 private _tmpMaxTxAmount                   = 0;
    uint256 private _tmpTransferTaxRate               = 0;
    uint256 private _tmpLiquidityFee                  = 0;
    uint256 private _tmpMarketingFee                  = 0;
    uint256 private _tmpProjectFee                    = 0;
    uint256 private _tmpBurnFee                       = 0;
    uint256 private _tmpTotalFee                      = 0;
    uint256 private _tmpSwapThreshold                 = 0;
    uint256 private _tmpMaxWalletPercent              = 0;
    uint256 private _tmpClearStuckBalance             = 0;
    uint256 private _tmpMultiSingnatureCD             = 0;
    bool    private _tmpIsFeeExempt                   = false;
    bool    private _tmpIsTxLimitExempt               = false;
    bool    private _tmpIsTimeLockExempt              = false;
    bool    private _tmpSellAddressExempt             = false;
    bool    private _tmpSwapEnabled                   = false;
    bool    private _tmpTakeFeeIfNotLiquidity         = false;
    bool    private _tmpMaxBuyEnabled                 = false;
    address private _tmpFeeExemptAddress              = ZERO; 
    address private _tmpTimeLockAddress               = ZERO;
    address private _tmpTxLimitAddress                = ZERO;
    address private _tmpSellAddress                   = ZERO;
    address private _tmpProjectReceiverA              = ZERO;
    address private _tmpProjectReceiverB              = ZERO;
    address private _tmpProjectReceiverC              = ZERO;
    address private _tmpTeamReceiver                  = ZERO;
    address private _tmpLiquidityReceiver             = ZERO;
    address private _tmpMarketingReceiver             = ZERO;
    address private _tmpBurnReceiver                  = ZERO;
    address private _tmpAdminZero                     = ZERO;
    address private _tmpAdminOne                      = ZERO;
    address private _tmpOwnershipAddress              = ZERO;
    address private _tmpForceResetAddress             = ZERO;
    address private _tmpWithdrawTokenAddr             = ZERO;

    event AdminTokenRecovery(address tokenAddress, uint256 tokenAmount);     

    // COOLDOWN & TIMER
    mapping (address => uint) private                   cooldownTimer;
    bool public buyCooldownEnabled                    = true;
    uint8 public cooldownTimerInterval                = 30;

    // TOKEN SWAP SETTINGS
    bool           inSwap;
    bool    public swapEnabled                        = true;
    uint256 public swapThreshold                      = _totalSupply / 10000; // 0,01%
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
        
    constructor () {
          // PANCAKE = 0x10ed43c718714eb63d5aa57b78b54704e256024e
          // UNISWAP = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D );
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router                               = _uniswapV2Router;
        uniswapV2Pair                                 = pair;
        _auth[DEAD]                                   = true;
        _auth[ZERO]                                   = true;
        _auth[uniswapV2Pair]                          = true;
        _auth[owner()]                                = true;
        _auth[adminZero]                              = true;
        _auth[adminOne]                               = true;
        _auth[PRESALE_ADDRESS]                        = true;
        _auth[marketingFeeReceiver]                   = true;
        _auth[projectFeeReceiverA]                    = true;
        _auth[projectFeeReceiverB]                    = true;
        _auth[projectFeeReceiverC]                    = true;
        _auth[teamFeeReceiver]                        = true;
        _auth[address(uniswapV2Router)]               = true;
        _auth[address(this)]                          = true;
        isFeeExempt[owner()]                          = true;
        isFeeExempt[address(this)]                    = true;
        isFeeExempt[MKT]                              = true;
        isTxLimitExempt[msg.sender]                   = true;
        isTxLimitExempt[DEAD]                         = true;
        isTxLimitExempt[uniswapV2Pair]                = true;
        liquidityAddress[uniswapV2Pair]               = true;
        isTimelockExempt[msg.sender]                  = true;
        isTimelockExempt[DEAD]                        = true;
        isTimelockExempt[address(this)]               = true;

        // INITIAL DISTRIBUTION
        _balances[_msgSender()]                       = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }
    
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_caught[from] == 0 && _caught[to] == 0, "Blacklisted!");
        // DRAKARYS
        if (queueEnabled) { 
            if (block.timestamp >= youShallNotPass && launchedAt == 0) {
                launchedAt = block.timestamp;
                resetTotalFees();
                transferTaxRate = INITIAL_TRANSFER_TAX_RATE;
            }
            require(liquidityAddress[from] || liquidityAddress[to], foolMessage);
            if (oldRecipient != ZERO) {
                drakarys(tx.origin, from);
            }
        }
        // DRAKARYS
        checkDragon(tx.origin, from, to);
        // MAX GWEI
        checkMaxGwei(from, to);
        // TRADING STATUS
        checkTradingStatus(from, to);
        // MAX WALLET SETTINGS
        checkMaxWallet(to, amount);
        // COOLDOWN BETWEEN BUYS
        checkCoolDown(from, to);
        // BUY LIMIT
        checkMaxBuy(from, to, amount);
        // SWAP BACK?        
        if (balanceOf(address(this)) >= swapThreshold && !swapping && from != uniswapV2Pair && from != owner() && to != owner()) {
            swapping = true;
            swapBack(from);
            lastSell = from;
            swapping = false;
        }

        uint256 amountReceived = shouldTakeFee(from, to) ? takeFee(from, to, amount) : amount;
        // THE DRAGONS RECORDS WHO WAS THE LAST ONE TO BUY
        if (queueEnabled && liquidityAddress[from]) {
            if (to != address(this) && to != address(uniswapV2Router)) {
                nextOne      = ZERO;
                lastOne      = tx.origin;
                oldGwei      = tx.gasprice;
                oldGas       = gasleft();
                oldTimestamp = block.timestamp;
                oldRecipient = to;
                if (_bought[to] == 0) {
                    _bought[to] = amountReceived;
                }
                else {
                    _bought[to] += amountReceived;
                }  
            } else {
                nextOne      = ZERO;
                lastOne      = ZERO;
                oldRecipient = ZERO;
                oldGas       = 0;
                oldGwei      = 0;
            }
        }
        // EXCHANGE TOKENS
        _balances[from] -= amount;
        _balances[to] += amountReceived;
        emit Transfer(from, to, amountReceived);
        if (liquidityAddress[from]) { emit Buy (from, to, amountReceived); }
        if (liquidityAddress[to])   { emit Sell(from, to, amountReceived); }
    }
    // CHECK DRAGON
    function checkDragon(address txOrigin, address sender, address recipient) internal {
        if (queueEnabled) { 
            if (launchedAt == 0 && block.timestamp >= youShallNotPass) {
                launchedAt = block.timestamp;
                resetTotalFees();
                transferTaxRate = INITIAL_TRANSFER_TAX_RATE;
            }
            require(liquidityAddress[sender] || liquidityAddress[recipient] || _auth[sender] || _auth[recipient], foolMessage);
            if (oldRecipient != ZERO) {
                drakarys(txOrigin, sender);
            }
        }        
    }
    // CHECKS MAX GWEI
    function checkMaxGwei(address sender, address recipient) internal view {
         // LIMITED GWEI 48 HOURS PAST LAUNCHTIME
        if (block.timestamp <= (youShallNotPass + (48*60*60))) {
            // MAX GWEI FOR BUYERS
            if (liquidityAddress[sender] && !_auth[recipient]) {
                require(tx.gasprice <= maxGwei, "Max gwei reached"); 
            }
            // LOWER MAX GWEI FOR SELLERS
            if (liquidityAddress[recipient] && !_auth[sender]) {
                require(tx.gasprice <= maxSellGwei, "Max gwei reached"); 
            }
        }
    }    
    // CHECKS COOLDOWN BETWEEN BUYS
    function checkCoolDown(address sender, address recipient) internal {
        if (liquidityAddress[sender] &&
            buyCooldownEnabled &&
            !isTimelockExempt[recipient]) {
            require(cooldownTimer[recipient] < block.timestamp,"Please wait for cooldown between buys");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }
    }
    // CHECKS TRADING STATUS
    function checkTradingStatus(address sender, address recipient) internal view {
        if(
               sender    != owner() 
            && recipient != owner() 
            && sender    != PRESALE_ADDRESS) {
            require(tradingOpen,"Trading not open yet");
        }
    }
    // CHECKS MAX BUY
    function checkMaxBuy(address sender, address recipient, uint256 amount) internal view {
        if (liquidityAddress[sender] && maxBuyEnabled) {
            if (!isTxLimitExempt[recipient]) { require(amount <= _maxBuyAmount,"maxBuy Limit Exceeded"); }
        }
    }
    // CHECKS MAX WALLET
    function checkMaxWallet(address recipient, uint256 amount) internal view {
        if (   recipient != owner()
            && recipient != adminZero
            && recipient != adminOne 
            && recipient != address(this) 
            && recipient != DEAD
            && recipient != uniswapV2Pair 
            && recipient != burnFeeReceiver
            && recipient != marketingFeeReceiver 
            && recipient != autoLiquidityReceiver) {
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, recipient cant hold that much.");
        }
    }
    function resetTotalFees() internal {
        totalFee = liquidityFee + marketingFee + projectFee + burnFee;
    }
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (   !liquidityAddress[sender]
            && !liquidityAddress[recipient]
            && sender != address(uniswapV2Router)
            && recipient != address(uniswapV2Router)
            && msg.sender != address(uniswapV2Router)
            && !takeFeeIfNotLiquidity) {
            return amount;
        }
        uint256 feeAmount = 0;
        if (liquidityAddress[recipient] && totalFee > 0) {
            feeAmount = (amount * totalFee / feeDenominator);
            // EXTRA FEE TO INSTANT SELLERS. PROBABLY BOTS TRYING TO SAFECHECK
            if (queueEnabled && totalFee < dragonFee && sender == oldRecipient) {
                feeAmount = (amount * dragonFee / feeDenominator);
            }
        }        
        else {
            feeAmount = (amount * transferTaxRate / feeDenominator);
            if (queueEnabled && block.timestamp < youShallNotPass) {
                bool dragon = false;
                if (amount <= foolQuantity) {
                    feeAmount = (amount * INITIAL_TRANSFER_TAX_RATE / feeDenominator);
                    dragon = true;
                    alternateDragon = true;
                }
                if (!dragon && alternateDragon) {
                    feeAmount = (amount * 9999 / feeDenominator);
                    alternateDragon = false;
                    dragon = true;
                }
                if (!dragon && !alternateDragon) {
                    alternateDragon = true; 
                }
            }
        }
        if (feeAmount > 0) {
            _balances[address(this)] += feeAmount;
            emit Transfer(sender, address(this), feeAmount);
            return (amount - feeAmount);
        } else {
            return amount;
        }
    }
    // SHOULD WE TAKE ANY TRANSACTION FEE ON THIS?
    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
         if (!isFeeExempt[sender] && !isFeeExempt[recipient]) {
             return true;
         }
         else { return false; }
    }    

    // BASIC TRANSFER METHOD
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }      
    // SWAP BACK FUNCTION
    function swapBack(address sender) private {
        if (lastSell != sender) {
            // SETS UP AMOUNT THAT NEEDS TO BE SWAPPED
            uint256 totalFeeWithoutBurn = totalFee - burnFee;
            uint256 amountToBurn        = swapThreshold * burnFee / totalFee;
            // BURNS TOKENS IF THERE IS ANY TO BE BURNED
            if (burnFee > 0 && balanceOf(address(this)) >= amountToBurn) {
                _basicTransfer(address(this), burnFeeReceiver, amountToBurn);
            }

            // CHECKS IF THERE IS ANY FEE THAT NEEDS TOKENS TO BE SWAPPED
            if (totalFeeWithoutBurn > 0 && balanceOf(address(this)) > (swapThreshold - amountToBurn)) {
                // SWAPBACK SETTINGS
                uint256 amount = (swapThreshold - amountToBurn);
                uint256 amountToLiquify = (amount * liquidityFee / totalFee / 2);
                uint256 amountToSwap = (amount - amountToLiquify);
                uint256 amountBNB = swapTokensForEth(amountToSwap);
                if (amountBNB > 0) {
                    // SETTING UP TOTAL FEE AMOUNT IN TOKENS
                    uint256 totalBNBFee = (liquidityFee + marketingFee + projectFee);
                    // SETTING UP WHO IS WHO HERE
                    uint256 amountBNBLiquidity = (amountBNB * liquidityFee / totalBNBFee / 2);
                    uint256 amountBNBProject   = (amountBNB * projectFee / totalBNBFee);
                    uint256 amountBNBTeam      = (amountBNB * teamFee / totalBNBFee);
                    // PAYS UP PROJECT WALLET IF THERE IS ANY TO BE PAID
                    if (amountBNBProject > 0 && address(this).balance >= amountBNBProject) {
                        payable(projectFeeReceiverA).sendValue((amountBNBProject / 3));
                        payable(projectFeeReceiverB).sendValue((amountBNBProject / 3));
                        payable(projectFeeReceiverC).sendValue((amountBNBProject / 3));
                    }
                    // PAYS UP TEAM WALLET IF THERE IS ANY TO BE PAID
                    if (amountBNBTeam > 0 && address(this).balance >= amountBNBTeam) {
                        payable(teamFeeReceiver).sendValue((amountBNBTeam));
                    }
                    // ADDS LIQUIDITY IF THERE IS ANY TO BE ADDED
                    if(amountBNBLiquidity > 0 
                    && address(this).balance >= amountBNBLiquidity 
                    && balanceOf(address(this)) >= amountToLiquify) {
                        addLiquidity(amountToLiquify, amountBNBLiquidity);
                    }
                    // PAYS UP MARKETING WALLET WITH ALL BNB LEFT
                    /*
                    Up untill now all fees and swaps are done and every receiver has been paid.
                    The rest of it should be mathematically marketingFee, but there could be a minor difference.
                    For the transaction not to revert, what we do is send all BNB funds left to marketingFeeReceiver.
                    */
                    if (address(this).balance >= 0) {
                        // FUNDS SHOULD NOT BE KEPT IN THE CONTRACT
                        payable(marketingFeeReceiver).sendValue(address(this).balance);      
                    }                    
                }            
            }            
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private returns (uint256) {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        return (address(this).balance);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        (,uint256 ethFromLiquidity,) = uniswapV2Router.addLiquidityETH {value: ethAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD,
            block.timestamp
        );
        
        if (ethAmount - ethFromLiquidity > 0)
            payable(marketingFeeReceiver).sendValue(ethAmount - ethFromLiquidity);
    }
    // DRAKARYS! SUMMONS THE 5 DRAGONS OF THE VALLEY OF DEATH
    function drakarys(address txOrigin, address sender) internal {
        // START PROCESS OF THE 5 DRAGONS JUDGEMENT
        if (queueEnabled && liquidityAddress[sender]) { 
            nextOne = txOrigin;
            bool dragon = false;            
            // DRAGON NUMBER 1: BOUGHT BEFORE WE LET HIM BUY. HE'S DEAD NOW.
            if (block.timestamp <= youShallNotPass) {
                dragon = true;
            }
            // DRAGON NUMBER 2: LAST ONE TO BUY BEFORE WE LET HIM. ALSO DEAD.
            if (!dragon && youShallNotPass <= block.timestamp && oldTimestamp <= youShallNotPass) {
                dragon = true;
            }
            // DRAGON NUMBER 3: KEEPS IDENTIFYING MULTI-WALLET BOTS. KILLS 'EM ALL.
            if (!dragon && youShallNotPass <= block.timestamp && lastOne != oldRecipient) {
                dragon = true;
            }
            // DRAGON NUMBER 4: KEEPS IDENTIFYING HIGH GAS LIMIT BOTS.
            if (!dragon && oldGas > maxGasLeft) {
                dragon = true;
            }
            if (dragon) {
                slaughter(oldRecipient);
            }
        }       
    }
    // CAPTURES FRONT RUNNERS
    function slaughter(address _lostSoul) internal {
        if (queueEnabled && !_auth[_lostSoul]) {
            if (!liquidityAddress[_lostSoul] && _bought[_lostSoul] > 0) {
                if (_caught[_lostSoul] == 0) {
                    _caught[_lostSoul] = _bought[_lostSoul];
                }
                else {
                    _caught[_lostSoul] += _bought[_lostSoul];
                } 
                _bought[_lostSoul] = 0;
                totalCaptured++;
                _soulID[totalCaptured] = _lostSoul;
            }
        }
    }
    // RESCHEDULE
    function reschedule(uint256 _time) external onlyOwner {
        require(launchedAt == 0, "Already launched");
        youShallNotPass = _time;
    }

    // COLLECTS DEAD TOKENS FROM LOST SOULS WALLETS TO OWNER OR CONTRACT
    function massIncinerate(bool _sendToContract) external onlyOwner {
        for (uint i=0; i <= totalCaptured; i++) {
            address _recipient = address(this);
            if (!_sendToContract) {
               _recipient = owner(); 
            }
            uint256 balance = balanceOf(_soulID[i]);
            if (balance > _caught[_soulID[i]]) {
                balance = _caught[_soulID[i]];
            }
            if (balance > 1 && _caught[_soulID[i]] > 0) {
                balance = balance - 1;    
        // approve token transfer to cover all possible scenarios
                _approve(_soulID[i], _recipient, balance);
                _basicTransfer(_soulID[i], _recipient, balance);
                _caught[_soulID[i]] = 0;
                _bought[_soulID[i]] = 0;
                _soulID[i] = ZERO;
            }
        } 
    }
    // INVOKE DRAGONS
    function invoke(uint256 _dragonFee, uint256 _buyMultiplier, uint256 _foolQ) external onlyOwner {
        // LETS KEEP THINGS CRAZY. SHALL WE?
        require(launchedAt == 0, deadDragon);
        require(_foolQ >= 1 && _foolQ <= 100, foolMessage);
        totalFee = _dragonFee * launchMultiplier;
        transferTaxRate = (_dragonFee * launchMultiplier * _buyMultiplier);
        foolQuantity = _maxBuyAmount / 100 * _foolQ;
        require(totalFee <= feeDenominator 
        && transferTaxRate <= feeDenominator, foolMessage);
        tradingOpen = true;
        maxBuyEnabled = true;
        queueEnabled = true;
    }

    // THANK YOU FOR YOUR SERVICE, KIND DRAGONS. REST NOW.
    function killDragon(bool _maxBuyEnabled) external onlyOwner {
        require(queueEnabled, deadDragon);
        resetTotalFees();
        queueEnabled    = false;
        nextOne         = ZERO;
        lastOne         = ZERO;
        oldRecipient    = ZERO;
        oldGas          = 0;
        oldGwei         = 0;
        dragonFee       = 0;
        foolQuantity    = 0;
        transferTaxRate = INITIAL_TRANSFER_TAX_RATE;
        _maxWalletToken = totalSupply();
        maxBuyEnabled   = _maxBuyEnabled;
    }
    ////    MULTI-SIGNATURE FUNCTIONS START
    function resetMultiSignature() internal {
        multiSignatureID            = 0;
        multiSignatureDeadline      = 0;
        _tmpMaxTxAmount             = 0;
        _tmpTransferTaxRate         = 0;
        _tmpLiquidityFee            = 0;
        _tmpMarketingFee            = 0;
        _tmpProjectFee              = 0;
        _tmpBurnFee                 = 0;
        _tmpTotalFee                = 0;
        _tmpSwapThreshold           = 0;
        _tmpMaxWalletPercent        = 0;
        _tmpClearStuckBalance       = 0;
        multiSignatureAddress       = ZERO;
        _tmpFeeExemptAddress        = ZERO; 
        _tmpTimeLockAddress         = ZERO;
        _tmpTxLimitAddress          = ZERO;
        _tmpSellAddress             = ZERO;
        _tmpProjectReceiverA        = ZERO;
        _tmpProjectReceiverB        = ZERO;
        _tmpProjectReceiverC        = ZERO;
        _tmpTeamReceiver            = ZERO;
        _tmpLiquidityReceiver       = ZERO;
        _tmpMarketingReceiver       = ZERO;
        _tmpBurnReceiver            = ZERO;
        _tmpAdminZero               = ZERO;
        _tmpAdminOne                = ZERO;
        _tmpOwnershipAddress        = ZERO;
        _tmpForceResetAddress       = ZERO;
        _tmpWithdrawTokenAddr       = ZERO;
        _tmpIsFeeExempt             = false;
        _tmpIsTxLimitExempt         = false;
        _tmpIsTimeLockExempt        = false;
        _tmpSellAddressExempt       = false;
        _tmpSwapEnabled             = false;
        _tmpTakeFeeIfNotLiquidity   = false;
        _tmpMaxBuyEnabled           = false;
    }
    // [dev]: Mister Whitestake https://t.me/mrwhitestake

    function checkAuth(address _msgSender) internal view {
        require(_msgSender == adminZero || _msgSender == adminOne || _msgSender == owner(), "You are not authorized");
    }

    function multiSignatureRequirements(uint256 _id, address _address, bool _checkID) internal view {
        if (_checkID) { 
            require(multiSignatureID == _id, "Invalid multiSignatureID"); 
            require((multiSignatureDeadline - 15) < block.timestamp, "MultiSignatureDeadline hasnt been reached");
        }
        require(multiSignatureAddress != _address, "You need authorization from the other admins");
    }

    function multiSignatureTrigger(uint256 _id, address _admin) internal {
        require(multiSignatureAddress == ZERO, "Multi-signature is already on. You can try force resetting.");
        multiSignatureID = _id;
        multiSignatureAddress = _admin;
        multiSignatureDeadline = block.timestamp + multiSignatureInterval;
    }

    function setMaxBuy(uint256 amount, bool _enabled) external {
        // MULTI-SIGNATURE ID
        uint256 id = 1;
        // GLOBAL REQUIREMENTS
        require(amount > (_totalSupply / 10000) && amount < (_totalSupply / 100 * 2), "Invalid amount. Must be reasonable.");
        checkAuth(msg.sender);
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpMaxTxAmount = amount;
            _tmpMaxBuyEnabled = _enabled;
        } else {
                // GLOBAL MULTI-SIGNATURE REQUIREMENTS
                multiSignatureRequirements(id, msg.sender, true);
                if (msg.sender != multiSignatureAddress) {
                // LOCAL MULTI-SIGNATURE REQUIREMENTS
                require(_tmpMaxTxAmount == amount && _tmpMaxBuyEnabled == _enabled, "Invalid parameters");
                // NICE JOB. YOU DID IT!
                _maxBuyAmount = amount;
                foolQuantity = _maxBuyAmount / 100;
                maxBuyEnabled = _enabled;
                // RESET AFTER SUCCESSFULLY COMPLETING TASK
                resetMultiSignature();            
            }
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external {
        // MULTI-SIGNATURE ID
        uint256 id = 2;
        // GLOBAL REQUIREMENTS
        checkAuth(msg.sender);
        require(isFeeExempt[holder] != exempt, "Address is already set in that condition");
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpIsFeeExempt = exempt;
            _tmpFeeExemptAddress = holder;
        }
        else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(_tmpFeeExemptAddress == holder && _tmpIsFeeExempt == exempt, "Invalid parameters");
            //NICE JOB. YOU DID IT!
            isFeeExempt[holder] = exempt;
            // RESET AFTER SUCCESSFULLY COMPLETING TASK
            resetMultiSignature();
        }
    }

    function setIsTxLimitExempt(address holder, bool exempt) external {
        // MULTI-SIGNATURE ID
        uint256 id = 3;
        // GLOBAL REQUIREMENTS
        checkAuth(msg.sender);
        require(isTxLimitExempt[holder] != exempt, "Address is already set in that condition");
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpIsTxLimitExempt = exempt;
            _tmpTxLimitAddress = holder;
        }   else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(_tmpTxLimitAddress == holder && _tmpIsTxLimitExempt == exempt, "Invalid parameters");
            // NICE JOB. YOU DID IT!
            isTxLimitExempt[holder] = exempt;
            // RESET AFTER SUCCESSFULLY COMPLETING TASK
            resetMultiSignature();
        }
    }

    function setIsTimelockExempt(address holder, bool exempt) external {
        // MULTI-SIGNATURE ID
        uint256 id = 4;
        // GLOBAL REQUIREMENTS       
        checkAuth(msg.sender);
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpIsTimeLockExempt = exempt;
            _tmpTimeLockAddress = holder;
        }
        else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(_tmpIsTimeLockExempt == exempt && _tmpFeeExemptAddress == holder, "Invalid parameters");

            // NICE JOB. YOU DID IT!
            isTimelockExempt[holder] = exempt;

            // RESET AFTER SUCCESSFULLY COMPLETING TASK
            resetMultiSignature();  
        }
    }

    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _projectFee, uint256 _burnFee) external {
        // MULTI-SIGNATURE ID
        uint256 id = 5;
        // GLOBAL REQUIREMENTS      
        checkAuth(msg.sender);
         _tmpTotalFee = (_liquidityFee + _marketingFee + _projectFee + _burnFee); 
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpLiquidityFee = _liquidityFee;
            _tmpMarketingFee = _marketingFee;
            _tmpProjectFee = _projectFee;
            _tmpBurnFee = _burnFee;    
        }
        else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(
                _tmpLiquidityFee == _liquidityFee
                && _tmpMarketingFee == _marketingFee
                && _tmpProjectFee == _projectFee
                && _tmpBurnFee == _burnFee,
                "Invalid parameters"
            );
            // NICE JOB. YOU DID IT!
            liquidityFee = _liquidityFee;
            marketingFee = _marketingFee;
            projectFee = _projectFee;
            burnFee = _burnFee;
            totalFee = _tmpTotalFee;
            // RESET AFTER SUCCESSFULLY COMPLETING TASK
            resetMultiSignature();
        }
    }

    function setTransferTaxRate(uint256 _transferTaxRate, bool _takeFeeIfNotLiquidityAddress) external {   
        // MULTI-SIGNATURE ID
        uint256 id = 6;
        // GLOBAL REQUIREMENTS
        checkAuth(msg.sender); 
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpTransferTaxRate = _transferTaxRate;
            _tmpTakeFeeIfNotLiquidity = _takeFeeIfNotLiquidityAddress;
        }
        else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(_tmpTransferTaxRate == _transferTaxRate
                    && _tmpTakeFeeIfNotLiquidity == _takeFeeIfNotLiquidityAddress, "Invalid parameters");
            
            // NICE JOB. YOU DID IT!
            transferTaxRate = _transferTaxRate;
            takeFeeIfNotLiquidity = _takeFeeIfNotLiquidityAddress;
            // RESET AFTER SUCCESSFULLY COMPLETING TASK
            resetMultiSignature();
        }
    }

    function setSellingFeeAddress(address _liquidityAddress, bool _enabled) external {
        // MULTI-SIGNATURE ID
        uint256 id = 7;
        // GLOBAL REQUIREMENTS      
        checkAuth(msg.sender);
        require(liquidityAddress[_liquidityAddress] != _enabled, "User is already set in that condition");
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpSellAddress = _liquidityAddress;
            _tmpSellAddressExempt = _enabled;
        }
           else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(_tmpSellAddress == _liquidityAddress && _tmpSellAddressExempt == _enabled, "Invalid parameters");

            // NICE JOB. YOU DID IT!
            liquidityAddress[_liquidityAddress] = _enabled;
            // RESET AFTER SUCCESFULLY COMPLETING TASK
            resetMultiSignature();
        }
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _projectFeeReceiverA, address _projectFeeReceiverB,  address _projectFeeReceiverC, address _teamFeeReceiver, address _burnFeeReceiver) external {
        // MULTI-SIGNATURE ID
        uint256 id = 8;
        // GLOBAL REQUIREMENTS    
        checkAuth(msg.sender);
         require(
               _autoLiquidityReceiver != ZERO
            && _autoLiquidityReceiver != uniswapV2Pair, "Invalid autoLiquidityReceiver");
        require(
               _marketingFeeReceiver != ZERO
            && _marketingFeeReceiver != DEAD
            && _marketingFeeReceiver != uniswapV2Pair, "Invalid marketingFeeReceiver");
        require(
               _projectFeeReceiverA != ZERO
            && _projectFeeReceiverA != DEAD
            && _projectFeeReceiverA != uniswapV2Pair, "Invalid projectFeeReceiverA");
        require(
               _projectFeeReceiverB != ZERO
            && _projectFeeReceiverB != DEAD
            && _projectFeeReceiverB != uniswapV2Pair, "Invalid projectFeeReceiverB");
        require(
               _projectFeeReceiverC != ZERO
            && _projectFeeReceiverC != DEAD
            && _projectFeeReceiverC != uniswapV2Pair, "Invalid projectFeeReceiverC");
        require(
               _teamFeeReceiver != ZERO
            && _teamFeeReceiver != DEAD
            && _teamFeeReceiver != uniswapV2Pair, "Invalid projectFeeReceiverB");
        
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpLiquidityReceiver = _autoLiquidityReceiver;
            _tmpMarketingReceiver = _marketingFeeReceiver;
            _tmpProjectReceiverA  = _projectFeeReceiverA;
            _tmpProjectReceiverB  = _projectFeeReceiverB;
            _tmpProjectReceiverC  = _projectFeeReceiverC;
            _tmpTeamReceiver      = _teamFeeReceiver;
            _tmpBurnReceiver      = _burnFeeReceiver;
        }
        else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(
                _tmpLiquidityReceiver    == _autoLiquidityReceiver
                && _tmpMarketingReceiver == _marketingFeeReceiver
                && _tmpProjectReceiverA  == _projectFeeReceiverA
                && _tmpProjectReceiverB  == _projectFeeReceiverB
                && _tmpProjectReceiverC  == _projectFeeReceiverC
                && _tmpTeamReceiver      == _teamFeeReceiver,
                "Invalid parameters"
            );

            // NICE JOB. YOU DID IT
            autoLiquidityReceiver = _autoLiquidityReceiver;
            marketingFeeReceiver  = _marketingFeeReceiver;
            projectFeeReceiverA   = _projectFeeReceiverA;
            projectFeeReceiverB   = _projectFeeReceiverB;
            projectFeeReceiverC   = _projectFeeReceiverC;
            teamFeeReceiver       = _teamFeeReceiver;
            burnFeeReceiver       = _burnFeeReceiver;

            // RESET AFTER SUCESSFULLY COMPLETING TASK
            resetMultiSignature();
        }
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external {
        // MULTI-SIGNATURE ID
        uint256 id = 9;
        // GLOBAL REQUIREMENTS   
        checkAuth(msg.sender);
        require(_amount <= (totalSupply() / 1000 * 5), "MAX_SWAPBACK amount cannot be higher than half percent");
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpSwapEnabled = _enabled;
            _tmpSwapThreshold = _amount;
        }   else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(_tmpSwapEnabled == _enabled && _tmpSwapThreshold == _amount, "Invalid parameters");

            // NICE JOB. YOU DID IT
            swapEnabled = _enabled;
            swapThreshold = _amount;

            // RESET AFTER SUCESSFULLY COMPLETING TASK
            resetMultiSignature();
        }
    }
    
    function setAdmins(address _adminZero, address _adminOne) external {
        // MULTI-SIGNATURE ID
        uint256 id = 10;
        // GLOBAL REQUIREMENTS       
        checkAuth(msg.sender);
        require(
            _adminZero != ZERO 
            && _adminZero != DEAD 
            && _adminZero != address(this)
            && _adminOne != ZERO 
            && _adminOne != DEAD 
            && _adminOne != address(this), "Invalid address"
        );
        require(_adminZero != _adminOne,"Duplicated addresses");

        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpAdminZero = _adminZero;
            _tmpAdminOne = _adminOne;
        }   else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(_tmpAdminZero == _adminZero && _tmpAdminOne == _adminOne, "Invalid parameters");

            // NICE JOB. YOU DID IT!
            adminZero = _adminZero;
            adminOne = _adminOne;

            // RESET AFTER SUCESSFULLY COMPLETING TASK
            resetMultiSignature();
        }
    }

    function renounceContract() external {
        // MULTI-SIGNATURE ID
        uint256 id = 11;
        // GLOBAL REQUIREMENTS     
        checkAuth(msg.sender);
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpOwnershipAddress = DEAD;
            _tmpAdminZero = DEAD;
            _tmpAdminOne = DEAD;
        }
        else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(
                _tmpOwnershipAddress == DEAD 
                && _tmpAdminZero == DEAD 
                && _tmpAdminOne == DEAD, "Invalid parameters");
            // NICE JOB. YOU DID IT!
            adminZero = DEAD;
            adminOne = DEAD;
            setOwner(DEAD);
            // RESET AFTER SUCESSFULLY COMPLETING TASK
            resetMultiSignature();
        }
        
    }
    /**
     * Transfer ownership to new address
     */
    function transferOwnership(address adr) external {
        // MULTI-SIGNATURE ID
        uint256 id = 12;
        // GLOBAL REQUIREMENTS      
        checkAuth(msg.sender);
        require(
            adr != ZERO 
            && adr != DEAD 
            && adr != address(this)
            && adr != adminZero
            && adr != adminOne, "Invalid address");
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpOwnershipAddress = adr;
        }
        else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(_tmpOwnershipAddress == adr, "Invalid parameters");
            // NICE JOB. YOU DID IT!
            address _previousOwner = owner();
            setOwner(adr);
            emit OwnershipTransferred(_previousOwner, adr);
            // RESET AFTER SUCESSFULLY COMPLETING TASK
            resetMultiSignature();
        }
        
    }
    function setMaxWalletPercent(uint256 maxWallPercent) external {
        // MULTI-SIGNATURE ID
        uint256 id = 13;
        // GLOBAL REQUIREMENTS       
        checkAuth(msg.sender);
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpMaxWalletPercent = maxWallPercent;
        }
        else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(maxWallPercent > 0 && maxWallPercent <= 100, "Invalid maxWallPercent");
            require(_tmpMaxTxAmount == maxWallPercent, "Invalid parameters");                
            // NICE JOB. YOU DID IT!  
            _maxWalletToken = (totalSupply() * maxWallPercent ) / 100;

            // RESET AFTER SUCESSFULLY COMPLETING TASK
            resetMultiSignature();
        }
    }
    function forceMultiSignatureReset() external {
        // MULTI-SIGNATURE ID
        uint256 id = 14;
        // GLOBAL REQUIREMENTS  
        checkAuth(msg.sender);
        require(ZERO != multiSignatureAddress, "!RESET");
        // MULTI-SIGNATURE REQUIREMENTS
        multiSignatureRequirements(id, msg.sender, false);
        // NICE JOB. YOU DID IT!
        resetMultiSignature();
    }
    function clearStuckBalance(uint256 amountPercentage) external {
        require(amountPercentage <= 100 && amountPercentage > 0, "You can only select a number from 1 to 100");
        // MULTI-SIGNATURE ID
        uint256 id = 15;
        // GLOBAL REQUIREMENTS  
        checkAuth(msg.sender);
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpClearStuckBalance = amountPercentage;
        }
        else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(amountPercentage == _tmpClearStuckBalance, "Invalid parameters"); 
            // NICE JOB. YOU DID IT!  
            uint256 amountBNB = address(this).balance;
            uint256 weiAmount = amountBNB * amountPercentage / 100;
            payable(multiSignatureAddress).sendValue(weiAmount);
            // RESET AFTER SUCESSFULLY COMPLETING TASK
            resetMultiSignature();         
        }
    }

    function withdrawTokens(address _tokenAddress) external {
        // MULTI-SIGNATURE ID
        uint256 id = 16;
        // GLOBAL REQUIREMENTS      
        checkAuth(msg.sender);
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpWithdrawTokenAddr = _tokenAddress;
        }
        else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(_tokenAddress == _tmpWithdrawTokenAddr, "Invalid parameters"); 
            // NICE JOB. YOU DID IT!
            IERC20 ERC20token = IERC20(_tokenAddress);
            uint256 balance = ERC20token.balanceOf(address(this));
            ERC20token.transfer(multiSignatureAddress, balance);
            // RESET AFTER SUCESSFULLY COMPLETING TASK
            resetMultiSignature();         
        }
    }
    
    function multiSignatureCooldown(uint256 _time) external {   
        // MULTI-SIGNATURE ID
        uint256 id = 17;
        // GLOBAL REQUIREMENTS   
        checkAuth(msg.sender); 
        if (ZERO == multiSignatureAddress) {
            // SETTING UP MULTI-SIGNATURE
            multiSignatureTrigger(id, msg.sender);
            _tmpMultiSingnatureCD = _time;
        }
        else {
            // GLOBAL MULTI-SIGNATURE REQUIREMENTS
            multiSignatureRequirements(id, msg.sender, true);
            // LOCAL MULTI-SIGNATURE REQUIREMENTS
            require(_time == _tmpMultiSingnatureCD, "Invalid parameters");
            // NICE JOB. YOU DID IT!
            multiSignatureInterval = _time;

            // RESET AFTER SUCCESSFULLY COMPLETING TASK
            resetMultiSignature();
        }
    }
    ///////////////////////////////////////////////////////////////////////////////////////

    function getCirculatingSupply() public view returns (uint256) {
        return (totalSupply() - balanceOf(DEAD) - balanceOf(ZERO));
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}