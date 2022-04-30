/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract ERC20Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "ERC20Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERC20Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
contract GAWK is Context, IERC20, ERC20Ownable {
    using SafeMath for uint256;

    string private constant _tokenName = "GAWK";
    string private constant _tokenSymbol = "GAWK";
    uint8 private constant _tokenDecimal = 18;

    uint256 private constant tMAX = ~uint256(0);
    uint256 private constant _tTotal = 1e11 * 10**18;
    uint256 private _rTotal = (tMAX - (tMAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public maxTokens;
	uint256 private minTokensForTaxSwap;
    address payable private MarketingAddress; //Marketing Wallet Address
    address payable private AppDevelopAddress; //Other Misc Wallet Address
    address payable private DevAddress; //Dev Wallet Address
    address payable public LiquidityAddress; //Liquidity Pool Token Owner. Gets set to BURN after inital LP is created.
    address dead = address(0xdead);
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address[] private _excluded;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private Excluded;
	mapping(address => bool) private ExcludedFromTax;
    mapping(address => bool) private MaxWalletExclude;
    mapping (address => bool) public isBotAddress;
    mapping(address => bool) public isSniperAddress;
	uint256 private MarketingTokens;
	uint256 private LiquidityTokens;
    uint256 private AppDevelopmentTokens;
    uint256 private totalBurnedTokens;
    uint256 private MarketingTax = 6;
    uint256 private prevMarketingTax = MarketingTax;
    uint256 private AppDevelopmentTax = 2;
    uint256 private prevAppDevelopmentTax = AppDevelopmentTax;
    uint256 private LiquidityTax = 2; 
    uint256 private prevLiquidityTax = LiquidityTax;
    uint256 private ReflectionsTax = 0; 
    uint256 private prevReflectionsTax = ReflectionsTax;
    uint256 private taxDivision = MarketingTax + AppDevelopmentTax + LiquidityTax;
    uint256 private buyMarketingTax = 6;
    uint256 private buyAppDevelopmentTax = 2; 
    uint256 private buyLiquidityTax = 2;
    uint256 private buyReflectionsTax = 0; 
    uint256 private sellMarketingTax = 6; 
    uint256 private sellAppDevelopmentTax = 2; 
    uint256 private sellLiquidityTax = 2;
    uint256 private sellReflectionsTax = 0; 
    uint256 private maxTokenPercent = 1;
    uint256 public ActiveTradeBlock = 0;
    uint256 public SniperPenaltyEndTime;
    bool public maxWallet = false;
    bool public limitsInEffect = false;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public live = false;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    constructor() payable {
        _rOwned[_msgSender()] = _rTotal / 100 * 5;
        _rOwned[address(this)] = _rTotal / 100 * 95;
        maxTokens = _tTotal * maxTokenPercent / 100;
        minTokensForTaxSwap = _tTotal * 5 / 10000; 
        MarketingAddress = payable(0xf4Fe4C3cF688Ae1eC71609Ea60dD1b4b0Cc4EBd0); 
        AppDevelopAddress = payable(0x83cD2e03378B59A0dc9707a5b1cfC379114f2eA2); 
        DevAddress = payable(0xeF01d68bEc0BC57575c525f15cE9707A75e2296f); 
        // LEAVE AS OWNER
        LiquidityAddress = payable(owner()); //Liquidity Pool Token Owner. Gets set to BURN after inital LP is created.
        Excluded[dead] = true;
        ExcludedFromTax[_msgSender()] = true;
        ExcludedFromTax[dead] = true;
        ExcludedFromTax[address(this)] = true;
        ExcludedFromTax[MarketingAddress] = true;
        ExcludedFromTax[AppDevelopAddress] = true;
        ExcludedFromTax[DevAddress] = true;
        MaxWalletExclude[address(this)] = true;
        MaxWalletExclude[_msgSender()] = true;
        MaxWalletExclude[dead] = true;
        MaxWalletExclude[MarketingAddress] = true;
        MaxWalletExclude[AppDevelopAddress] = true;
        MaxWalletExclude[DevAddress] = true;
        AddBot(0x41B0320bEb1563A048e2431c8C1cC155A0DFA967);
        AddBot(0x91B305F0890Fd0534B66D8d479da6529C35A3eeC);
        AddBot(0x7F5622afb5CEfbA39f96CA3b2814eCF0E383AAA4);
        AddBot(0xfcf6a3d7eb8c62a5256a020e48f153c6D5Dd6909);
        AddBot(0x74BC89a9e831ab5f33b90607Dd9eB5E01452A064);
        AddBot(0x1F53592C3aA6b827C64C4a3174523182c52Ece84);
        AddBot(0x460545C01c4246194C2e511F166D84bbC8a07608);
        AddBot(0x2E5d67a1d15ccCF65152B3A8ec5315E73461fBcd);
        AddBot(0xb5aF12B837aAf602298B3385640F61a0fF0F4E0d);
        AddBot(0xEd3e444A30Bd440FBab5933dCCC652959DfCB5Ba);
        AddBot(0xEC366bbA6266ac8960198075B14FC1D38ea7de88);
        AddBot(0x10Bf6836600D7cFE1c06b145A8Ac774F8Ba91FDD);
        AddBot(0x44ae54e28d082C98D53eF5593CE54bB231e565E7);
        AddBot(0xa3e820006F8553d5AC9F64A2d2B581501eE24FcF);
		AddBot(0x2228476AC5242e38d5864068B8c6aB61d6bA2222);
		AddBot(0xcC7e3c4a8208172CA4c4aB8E1b8B4AE775Ebd5a8);
		AddBot(0x5b3EE79BbBDb5B032eEAA65C689C119748a7192A);
		AddBot(0x4ddA45d3E9BF453dc95fcD7c783Fe6ff9192d1BA);

        emit Transfer(address(0), _msgSender(), _tTotal * 5 / 100);
        emit Transfer(address(0), address(this), _tTotal * 95 / 100);
    }
    receive() external payable {}
    function name() public pure override returns (string memory) {
        return _tokenName;
    }
    function symbol() public pure override returns (string memory) {
        return _tokenSymbol;
    }
    function decimals() public pure override returns (uint8) {
        return _tokenDecimal;
    }
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (Excluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
    function transferFrom(address sender,address recipient,uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),
        _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amt must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amt must be less than tot refl");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getValues(uint256 tAmount) private view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
    function _getTValues(uint256 tAmount)private view returns (uint256,uint256,uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }
    function _getRValues(uint256 tAmount,uint256 tFee,uint256 tLiquidity,uint256 currentRate) private pure returns (uint256,uint256,uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    function _takeLiquidity(uint256 tLiquidity) private {
        MarketingTokens += tLiquidity * MarketingTax / taxDivision;
        AppDevelopmentTokens += tLiquidity * AppDevelopmentTax / taxDivision;
        LiquidityTokens += tLiquidity * LiquidityTax / taxDivision;
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (Excluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(ReflectionsTax).div(10**2);
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(MarketingTax + AppDevelopmentTax + LiquidityTax).div(10**2);
    }
    function GoLive() external onlyOwner returns (bool){
        require(!live, "Trades already Live!");
        maxWallet = true;
        swapAndLiquifyEnabled = true;
        limitsInEffect = true;
        live = true;
        ActiveTradeBlock = block.number;
        SniperPenaltyEndTime = block.timestamp + 96 hours;
        IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniV2Router;
        MaxWalletExclude[address(uniswapV2Router)] = true;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniV2Router.factory()).createPair(address(this), _uniV2Router.WETH());
        MaxWalletExclude[address(uniswapV2Pair)] = true;
        require(address(this).balance > 0, "Must have ETH on contract to Open Market!");
        addLiquidity(balanceOf(address(this)), address(this).balance);
        setLiquidityAddress(dead);
        return true;
    }
    function _approve(address owner,address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBotAddress[from]);
        if(!live){
            require(ExcludedFromTax[from] || ExcludedFromTax[to], "Trading Is Not Live!");
        }
        if (maxWallet && !MaxWalletExclude[to]) {
            require(balanceOf(to) + amount <= maxTokens, "Max amount of tokens for wallet reached!");
        }
        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != dead && !inSwapAndLiquify) {
                if(from != owner() && to != uniswapV2Pair) {
                    for (uint x = 0; x < 3; x++) {
                    if(block.number == ActiveTradeBlock + x) {
                        isSniperAddress[to] = true;
                        }
                    }
                }
            }
        }
        uint256 totalTokensToSwap = LiquidityTokens.add(MarketingTokens).add(AppDevelopmentTokens);
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minTokensForTaxSwap;
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && balanceOf(uniswapV2Pair) > 0 && totalTokensToSwap > 0 && !ExcludedFromTax[to] && !ExcludedFromTax[from] && to == uniswapV2Pair && overMinimumTokenBalance) {
            swapTaxTokens();
            }
        bool takeFee = true;
        if (ExcludedFromTax[from] || ExcludedFromTax[to]) {
            takeFee = false;
        } else {
            if (from == uniswapV2Pair) {
                removeAllFee();
                MarketingTax = buyMarketingTax;
                AppDevelopmentTax = buyAppDevelopmentTax;
                ReflectionsTax = buyReflectionsTax;
                LiquidityTax = buyLiquidityTax;
            } 
            else if (to == uniswapV2Pair) {
                removeAllFee();
                MarketingTax = sellMarketingTax;
                AppDevelopmentTax = sellAppDevelopmentTax;
                ReflectionsTax = sellReflectionsTax;
                LiquidityTax = sellLiquidityTax;
                if(isSniperAddress[from] && SniperPenaltyEndTime > block.timestamp) {
                    MarketingTax = 95;
                }
            } else {
                require(!isSniperAddress[from] || SniperPenaltyEndTime <= block.timestamp);
                removeAllFee();
            }
        }
        _tokenTransfer(from, to, amount, takeFee);
    }
    function swapTaxTokens() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = MarketingTokens + AppDevelopmentTokens + LiquidityTokens;
        uint256 swapLiquidityTokens = LiquidityTokens.div(2);
        uint256 amountToSwapForETH = contractBalance.sub(swapLiquidityTokens);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForETH(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(MarketingTokens).div(totalTokensToSwap);
        uint256 ethForAppDev = ethBalance.mul(AppDevelopmentTokens).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance.sub(ethForMarketing).sub(ethForAppDev);
        MarketingTokens = 0;
        AppDevelopmentTokens = 0;
        LiquidityTokens = 0;
        (bool success,) = address(MarketingAddress).call{value: ethForMarketing}("");
        (success,) = address(AppDevelopAddress).call{value: ethForAppDev}("");
        addLiquidity(swapLiquidityTokens, ethForLiquidity);
        if(address(this).balance > 5 * 10**17){
            (success,) = address(DevAddress).call{value: address(this).balance}("");
        }
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            LiquidityAddress,
            block.timestamp
        );
    }
    function removeAllFee() private {
        if (LiquidityTax == 0 && MarketingTax == 0 && AppDevelopmentTax == 0 && ReflectionsTax == 0) return;
        prevLiquidityTax = LiquidityTax;
        prevMarketingTax = MarketingTax;
        prevAppDevelopmentTax = AppDevelopmentTax;
        prevReflectionsTax = ReflectionsTax;

        LiquidityTax = 0;
        MarketingTax = 0;
        AppDevelopmentTax = 0;
        ReflectionsTax = 0;
    }
    function restoreAllFee() private {
        MarketingTax = prevMarketingTax;
        AppDevelopmentTax = prevAppDevelopmentTax;
        ReflectionsTax = prevReflectionsTax;
        LiquidityTax = prevLiquidityTax;
    }
    function _tokenTransfer(address sender,address recipient,uint256 amount,bool takeFee) private {
        if (!takeFee) removeAllFee();
        if (Excluded[sender] && !Excluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!Excluded[sender] && Excluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!Excluded[sender] && !Excluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (Excluded[sender] && Excluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if (!takeFee) restoreAllFee();
    }
    function _transferStandard(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _tokenTransferNoFee(address sender,address recipient,uint256 amount) private {
        _rOwned[sender] = _rOwned[sender].sub(amount);
        _rOwned[recipient] = _rOwned[recipient].add(amount);

        if (Excluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        }
        if (Excluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }
    function setLiquidityAddress(address _LPAddress) internal {
        LiquidityAddress = payable(_LPAddress);
        ExcludedFromTax[LiquidityAddress] = true;
    }
    function ownerSetLiquidityAddress(address _LPAddress) external onlyOwner {
        LiquidityAddress = payable(_LPAddress);
        ExcludedFromTax[LiquidityAddress] = true;
    }
    function excludeFromTax(address account) external onlyOwner {
        ExcludedFromTax[account] = true;
    }
    function includeInTax(address account) external onlyOwner {
        ExcludedFromTax[account] = false;
    }
    function excludeFromMaxTokens(address account) external onlyOwner {
        MaxWalletExclude[account] = true;
    }
    function includeInMaxTokens(address account) external onlyOwner {
        MaxWalletExclude[account] = false;
    }
    function AddBot(address _user) public onlyOwner {
        require(!isBotAddress[_user]);
        isBotAddress[_user] = true;
    }
	function RemoveBot(address _user) public onlyOwner {
        require(isBotAddress[_user]);
        isBotAddress[_user] = false;
    }
    function removeSniper(address account) external onlyOwner {
        require(isSniperAddress[account]);
        isSniperAddress[account] = false;
    }
    function removeLimits() external onlyOwner {
        limitsInEffect = true;
    }
    function resumeLimits() external onlyOwner {
        limitsInEffect = false;
    }
    function TaxSwapEnable() external onlyOwner {
        swapAndLiquifyEnabled = true;
    }
    function TaxSwapDisable() external onlyOwner {
        swapAndLiquifyEnabled = false;
    }
    function enableMaxWallet() external onlyOwner {
        maxWallet = true;
    }
    function disableMaxWallet() external onlyOwner {
        maxWallet = false;
    }
    function setMaxWallet(uint256 _percent) external onlyOwner {
        maxTokens = _tTotal * _percent / 100;
        require(maxTokens <= _tTotal * 3 / 100, "Cannot set max wallet to more then 3% of total supply");
    }
    function ManualTaxSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= _tTotal * 1 / 10000, "Can only swap back if more than 0.01% of tokens stuck on contract");
        swapTaxTokens();
    }
    function withdrawETH() public onlyOwner {
        bool success;
        (success,) = address(DevAddress).call{value: address(this).balance}("");
    }
    function withdrawTokens(uint256 _percent, address _address) public onlyOwner {
        MarketingTokens = 0;
        AppDevelopmentTokens = 0;
        LiquidityTokens = 0;
        uint256 amount = balanceOf(address(this)) * _percent / 10**2;
        require(amount > 0, "Must have Tokens on CA");
        _transfer(address(this), _address, amount);
    }
    function setBuyTaxes(uint256 _buyMarketingTax, uint256 _buyAppDevelopmentTax, uint256 _buyLiquidityTax, uint256 _buyReflectionsTax) external onlyOwner {
        buyMarketingTax = _buyMarketingTax;
        buyAppDevelopmentTax = _buyAppDevelopmentTax;
        buyLiquidityTax = _buyLiquidityTax;
        buyReflectionsTax = _buyReflectionsTax;
    }
    function setSellTaxes(uint256 _sellMarketingTax, uint256 _sellAppDevelopmentTax, uint256 _sellLiquidityTax, uint256 _sellReflectionsTax) external onlyOwner {
        sellMarketingTax = _sellMarketingTax;
        sellAppDevelopmentTax = _sellAppDevelopmentTax;
        sellLiquidityTax = _sellLiquidityTax;
        sellReflectionsTax = _sellReflectionsTax;
    }
    function viewBuyTaxes() public view returns(uint256 BuyMarketing, uint256 buyAppDevelopment, uint256 buyLiquidity, uint256 buyReflections) {
        return(buyMarketingTax,buyAppDevelopmentTax,buyLiquidityTax,buyReflections);
    }
    function viewSellTaxes() public view returns(uint256 sellMarketing, uint256 sellAppDevelopment, uint256 sellLiquidity, uint256 sellReflections) {
        return (sellMarketingTax,sellAppDevelopmentTax,sellLiquidityTax,sellReflections);
    }
    function manualBurnTokens(uint256 percent) external onlyOwner returns (bool){
        require(percent <= 10, "May not nuke more than 10% of tokens in LP");
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);
        uint256 amountToBurn = liquidityPairBalance * percent / 10**2;
        if (amountToBurn > 0){
            _transfer(uniswapV2Pair, dead, amountToBurn);
        }
        totalBurnedTokens = balanceOf(dead);
        require(totalBurnedTokens <= _tTotal * 50 / 10**2, "Can not burn more then 50% of supply");
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
        return true;
    }
    function AirDrop(address[] memory wallets, uint256[] memory percent) external onlyOwner{
        require(wallets.length < 10, "Can only airdrop 100 wallets per txn due to gas limits");
        for(uint256 i = 0; i < wallets.length; i++){
            address wallet = wallets[i];
            uint256 amount = _tTotal * percent[i] / 100;
            _transfer(msg.sender, wallet, amount);
        }
    }
}