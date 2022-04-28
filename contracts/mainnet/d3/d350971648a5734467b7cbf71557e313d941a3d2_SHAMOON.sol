/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: UNLICENSED // THIS IS FOR THE WHALES SHAMOON TO THE MOON - SAFU DEV 
pragma solidity ^0.8.7;
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
contract SHAMOON is Context, IERC20, ERC20Ownable {
    using SafeMath for uint256;
    string private constant tokenName = "SHAMOON";
    string private constant tokenSymbol = "SHAMOON";
    uint8 private constant tokenDecimal = 18;

    uint256 private constant tMAX = ~uint256(0);
    uint256 private constant _tTotal = 1e10 * 10**18;
    uint256 private _rTotal = (tMAX - (tMAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private maximumTokens;
	uint256 private minimumTokensForTaxSwap;
    address payable private MWAddress; //Marketing Wallet Address
    address payable private OWAddress; //Other Misc Wallet Address
    address payable private DWAddress; //Dev Wallet Address
    address payable public LQPAddress; //Liquidity Pool Token Owner. Gets set to BURN after inital LP is created.
    address burn = address(0xdead);
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address[] private _excluded;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private Excluded;
	mapping(address => bool) private ExcludedFromTax;
    mapping(address => bool) private MaxWalletExclude;
    mapping (address => bool) public BotAddress;
    mapping(address => bool) public SniperAddress;
	uint256 private MarketingTokens;
	uint256 private LiquidityTokens;
    uint256 private MiscTokens;
    uint256 private BurnGiveAwayTokens;

    //Place Holders: Overridden each txn
    uint256 private MWTax = 7; //Marketing Tax
    uint256 private prevMWTax = MWTax;
    uint256 private OWTax = 5; //Misc/Other Tax
    uint256 private prevOWTax = OWTax;
    uint256 private LQTax = 6; //Liquidity Tax
    uint256 private prevLQTax = LQTax;
    uint256 private BGWTax = 0; //Burn/GiveAway Tax
    uint256 private prevBGWTax = BGWTax;
    uint256 private REFTax = 0; //Reflections Tax
    uint256 private prevREFTax = REFTax;
    uint256 private LQDivision = MWTax + OWTax + LQTax + BGWTax;

    uint256 private buyMWTax = 0; //Buy Marketing Tax
    uint256 private buyOWTax = 0; //Buy Misc/Other Tax
    uint256 private buyLQTax = 0; //Buy Liquidity Tax
    uint256 private buyBGWTax = 0; //Buy Burn/GiveAway Tax
    uint256 private buyREFTax = 0; //Buy Reflections Tax

    uint256 private sellMWTax = 6; //Sell Marketing Tax
    uint256 private sellOWTax = 5; //Sell Misc/Other Tax
    uint256 private sellLQTax = 2; //Sell Liquidity Tax
    uint256 private sellBGWTax = 4; //Sell Burn/GiveAway Tax
    uint256 private sellREFTax = 0; //Sell Reflections Tax

    uint256 public MarketOpenedBlock = 0;
    bool public maxTokensAllowed = false;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public OpenTrades = false;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    constructor() payable {
        _rOwned[address(this)] = _rTotal;
        maximumTokens = _tTotal * 2 / 100; // Max Tokens Allowed Per-Wallet is 2.5% of total supply
        minimumTokensForTaxSwap = _tTotal * 5 / 10000; //Min Tokens Needed for TaxSwap is 0.05% of total supply
        MWAddress = payable(0xB6a479918512c975F7D728e6aF5eaF9F992ccE73); //Marketing Wallet Address
        OWAddress = payable(0x1ede20ea6AD4BB991fa6B451ec1D28d57E1A958A); //Other Misc Wallet Address
        DWAddress = payable(0xab30d156c6697AB654345dEba2B92fa419Bce681); //Dev Wallet Address

        // LEAVE AS OWNER
        LQPAddress = payable(owner()); //Liquidity Pool Token Owner. Gets set to BURN after inital LP is created.

        Excluded[burn] = true;
        ExcludedFromTax[_msgSender()] = true;
        ExcludedFromTax[burn] = true;
        ExcludedFromTax[address(this)] = true;
        ExcludedFromTax[MWAddress] = true;
        ExcludedFromTax[OWAddress] = true;
        ExcludedFromTax[DWAddress] = true;
        MaxWalletExclude[address(this)] = true;
        MaxWalletExclude[_msgSender()] = true;
        MaxWalletExclude[burn] = true;
        MaxWalletExclude[MWAddress] = true;
        MaxWalletExclude[OWAddress] = true;
        MaxWalletExclude[DWAddress] = true;

        emit Transfer(address(0), address(this), _tTotal);
    }
    receive() external payable {}
    function name() public pure override returns (string memory) {
        return tokenName;
    }
    function symbol() public pure override returns (string memory) {
        return tokenSymbol;
    }
    function decimals() public pure override returns (uint8) {
        return tokenDecimal;
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
        MarketingTokens += tLiquidity * MWTax / LQDivision;
        BurnGiveAwayTokens += tLiquidity * BGWTax / LQDivision;
        MiscTokens += tLiquidity * OWTax / LQDivision;
        LiquidityTokens += tLiquidity * LQTax / LQDivision;
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (Excluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(REFTax).div(10**2);
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(MWTax + OWTax + BGWTax + LQTax).div(10**2);
    }
    function OpenMarket() external onlyOwner returns (bool){
        require(!OpenTrades, "Market already Open!");
        maxTokensAllowed = true;
        swapAndLiquifyEnabled = true;
        OpenTrades = true;
        MarketOpenedBlock = block.number;
        IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniV2Router;
        MaxWalletExclude[address(uniswapV2Router)] = true;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniV2Router.factory()).createPair(address(this), _uniV2Router.WETH());
        MaxWalletExclude[address(uniswapV2Pair)] = true;
        require(address(this).balance > 0, "Must have ETH on contract to Open Market!");
        addLiquidity(balanceOf(address(this)), address(this).balance);
        setLQPAddress(burn);
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
        require(!BotAddress[from]);
        if(!OpenTrades){
            require(ExcludedFromTax[from] || ExcludedFromTax[to], "Market is not yet Open!");
        }
        if (maxTokensAllowed == true && ! MaxWalletExclude[to]) {
            require(balanceOf(to) + amount <= maximumTokens, "Max amount of tokens for wallet reached!");
        }
        if (from != owner() && to != owner() && to != address(0) && to != burn && !inSwapAndLiquify) {
            if(from != owner() && to != uniswapV2Pair) {
                if(block.number == MarketOpenedBlock) {
                    SniperAddress[to] = true;
                }
            }
        }
        uint256 totalTokensToSwap = LiquidityTokens.add(MarketingTokens).add(MiscTokens);
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensForTaxSwap;
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && balanceOf(uniswapV2Pair) > 0 && totalTokensToSwap > 0 && !ExcludedFromTax[to] && !ExcludedFromTax[from] && to == uniswapV2Pair && overMinimumTokenBalance) {
            doTaxSwap();
            }
        bool takeFee = true;
        if (ExcludedFromTax[from] || ExcludedFromTax[to]) {
            takeFee = false;
        } else {
            if (from == uniswapV2Pair) {
                removeAllTax();
                MWTax = buyMWTax;
                BGWTax = buyBGWTax;
                OWTax = buyOWTax;
                REFTax = buyREFTax;
                LQTax = buyLQTax;
            } 
            else if (to == uniswapV2Pair) {
                removeAllTax();
                MWTax = sellMWTax;
                BGWTax = sellBGWTax;
                OWTax = sellOWTax;
                REFTax = sellREFTax;
                LQTax = sellLQTax;
                if(SniperAddress[from]) {
                    MWTax = 95;
                }
            } else {
                require(!SniperAddress[from]);
                removeAllTax();
            }
        }
        _tokenTransfer(from, to, amount, takeFee);
    }
    function doTaxSwap() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = MarketingTokens + MiscTokens + LiquidityTokens;
        uint256 swapLiquidityTokens = LiquidityTokens.div(2);
        uint256 amountToSwapForETH = contractBalance.sub(swapLiquidityTokens).sub(BurnGiveAwayTokens);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForETH(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(MarketingTokens).div(totalTokensToSwap);
        uint256 ethForMisc = ethBalance.mul(MiscTokens).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance.sub(ethForMarketing).sub(ethForMisc);
        MarketingTokens = 0;
        MiscTokens = 0;
        LiquidityTokens = 0;
        (bool success,) = address(MWAddress).call{value: ethForMarketing}("");
        (success,) = address(OWAddress).call{value: ethForMisc}("");
        addLiquidity(swapLiquidityTokens, ethForLiquidity);
        if(address(this).balance > 5 * 10**17){
            (success,) = address(DWAddress).call{value: address(this).balance}("");
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
            LQPAddress,
            block.timestamp
        );
    }
    function removeAllTax() private {
        if (LQTax == 0 && MWTax == 0 && BGWTax == 0 && OWTax == 0 && REFTax == 0) return;
        prevLQTax = LQTax;
        prevMWTax = MWTax;
        prevOWTax = OWTax;
        prevBGWTax = BGWTax;
        prevREFTax = REFTax;

        LQTax = 0;
        MWTax = 0;
        OWTax = 0;
        BGWTax = 0;
        REFTax = 0;
    }
    function restoreAllTax() private {
        MWTax = prevMWTax;
        OWTax = prevOWTax;
        BGWTax = prevBGWTax;
        REFTax = prevREFTax;
        LQTax = prevLQTax;
    }
    function _tokenTransfer(address sender,address recipient,uint256 amount,bool takeFee) private {
        if (!takeFee) removeAllTax();
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
        if (!takeFee) restoreAllTax();
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
    function setLQPAddress(address _LQPAddress) internal {
        LQPAddress = payable(_LQPAddress);
        ExcludedFromTax[LQPAddress] = true;
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
        require(!BotAddress[_user]);
        BotAddress[_user] = true;
    }
	function RemoveBot(address _user) public onlyOwner {
        require(BotAddress[_user]);
        BotAddress[_user] = false;
    }
    function removeSniper(address account) external onlyOwner {
        SniperAddress[account] = false;
    }
    function ManualTaxSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= _tTotal * 1 / 10000, "Can only swap back if more than 0.01% of tokens stuck on contract");
        doTaxSwap();
    }
    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success,) = address(DWAddress).call{value: address(this).balance}("");
    }
    function withdrawTokens(uint256 _percent, address _address) public onlyOwner {
        uint256 amount = balanceOf(address(this)) * _percent / 10**2;
        require(amount > 0, "Must have Tokens on CA");
        _transfer(address(this), _address, amount);
    }
    function BurnOrGiveAwayTokens(uint256 _percent, address _address) public onlyOwner {
        uint256 amountToBurnExtract = BurnGiveAwayTokens * _percent / 10**2;
        require(amountToBurnExtract > 0, "Must have Tokens for Burn on CA");
        _transfer(address(this), _address, amountToBurnExtract);
        BurnGiveAwayTokens -= amountToBurnExtract;
    }
    function setBuyTaxes(uint256 _buyMarketingTax, uint256 _buyOtherTax, uint256 _buyBurnTax, uint256 _buyLiquidityTax, uint256 _buyReflectionsTax) external onlyOwner {
        buyMWTax = _buyMarketingTax;
        buyOWTax = _buyOtherTax;
        buyBGWTax = _buyBurnTax;
        buyLQTax = _buyLiquidityTax;
        buyREFTax = _buyReflectionsTax;
    }
    function setSellTaxes(uint256 _sellMarketingTax, uint256 _sellOtherTax, uint256 _sellBurnTax, uint256 _sellLiquidityTax, uint256 _sellReflectionsTax) external onlyOwner {
        sellMWTax = _sellMarketingTax;
        sellOWTax = _sellOtherTax;
        sellBGWTax = _sellBurnTax;
        sellLQTax = _sellLiquidityTax;
        sellREFTax = _sellReflectionsTax;
    }
    function Taxes() public view returns(uint256 BuyMarketing, uint256 buyDev, uint256 buyLiquidity, uint256 sellMarketing, uint256 sellDev, uint256 sellLiquidity){
        return(buyMWTax,buyOWTax,buyLQTax,sellMWTax,sellOWTax,sellLQTax);
    }
}