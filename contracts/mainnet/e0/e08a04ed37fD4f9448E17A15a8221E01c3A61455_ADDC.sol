// SPDX-License-Identifier: MIT
// https://t.me/addcportal
// https://antidogedogeclub.com/
interface IUniswapV2Factory { event PairCreated( address indexed token0, address indexed token1, address pair, uint ); function feeTo() external view returns (address); function feeToSetter() external view returns (address); function getPair( address tokenA, address tokenB ) external view returns (address pair); function allPairs(uint) external view returns (address pair); function allPairsLength() external view returns (uint); function createPair( address tokenA, address tokenB ) external returns (address pair); function setFeeTo(address) external; function setFeeToSetter(address) external; }
interface IUniswapV2Router01 { function factory() external pure returns (address); function WETH() external pure returns (address); function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB, uint liquidity); function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity); function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB); function removeLiquidityETH( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountToken, uint amountETH); function removeLiquidityWithPermit( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountA, uint amountB); function removeLiquidityETHWithPermit( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountToken, uint amountETH); function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); function swapExactETHForTokens( uint amountOutMin, address[] calldata path, address to, uint deadline ) external payable returns (uint[] memory amounts); function swapTokensForExactETH( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); function swapExactTokensForETH( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); function swapETHForExactTokens( uint amountOut, address[] calldata path, address to, uint deadline ) external payable returns (uint[] memory amounts); function quote( uint amountA, uint reserveA, uint reserveB ) external pure returns (uint amountB); function getAmountOut( uint amountIn, uint reserveIn, uint reserveOut ) external pure returns (uint amountOut); function getAmountIn( uint amountOut, uint reserveIn, uint reserveOut ) external pure returns (uint amountIn); function getAmountsOut( uint amountIn, address[] calldata path ) external view returns (uint[] memory amounts); function getAmountsIn( uint amountOut, address[] calldata path ) external view returns (uint[] memory amounts); }
interface IUniswapV2Router02 is IUniswapV2Router01 { function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountETH); function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountETH); function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external; function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline ) external payable; function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external; }
interface IUniswapV2Pair { event Approval(address indexed owner, address indexed spender, uint value); event Transfer(address indexed from, address indexed to, uint value); function name() external pure returns (string memory); function symbol() external pure returns (string memory); function decimals() external pure returns (uint8); function totalSupply() external view returns (uint); function balanceOf(address owner) external view returns (uint); function allowance( address owner, address spender ) external view returns (uint); function approve(address spender, uint value) external returns (bool); function transfer(address to, uint value) external returns (bool); function transferFrom( address from, address to, uint value ) external returns (bool); function DOMAIN_SEPARATOR() external view returns (bytes32); function PERMIT_TYPEHASH() external pure returns (bytes32); function nonces(address owner) external view returns (uint); function permit( address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s ) external; event Mint(address indexed sender, uint amount0, uint amount1); event Burn( address indexed sender, uint amount0, uint amount1, address indexed to ); event Swap( address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to ); event Sync(uint112 reserve0, uint112 reserve1); function MINIMUM_LIQUIDITY() external pure returns (uint); function factory() external view returns (address); function token0() external view returns (address); function token1() external view returns (address); function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast); function price0CumulativeLast() external view returns (uint); function price1CumulativeLast() external view returns (uint); function kLast() external view returns (uint); function mint(address to) external returns (uint liquidity); function burn(address to) external returns (uint amount0, uint amount1); function swap( uint amount0Out, uint amount1Out, address to, bytes calldata data ) external; function skim(address to) external; function sync() external; function initialize(address, address) external; }

interface IERC20 { function totalSupply() external view returns (uint256); function balanceOf(address account) external view returns (uint256); function transfer( address recipient, uint256 amount ) external returns (bool); function allowance( address owner, address spender ) external view returns (uint256); function approve(address spender, uint256 amount) external returns (bool); function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool); event Transfer(address indexed from, address indexed to, uint256 value); event Approval( address indexed owner, address indexed spender, uint256 value ); }
interface IERC20Metadata is IERC20 { function name() external view returns (string memory); function symbol() external view returns (string memory); function decimals() external view returns (uint8); }

library SafeMath {
    function tryAdd( uint256 a, uint256 b ) internal pure returns (bool, uint256) { unchecked { uint256 c = a + b; if (c < a) return (false, 0); return (true, c); } }
    function trySub( uint256 a, uint256 b ) internal pure returns (bool, uint256) { unchecked { if (b > a) return (false, 0); return (true, a - b); } }
    function tryMul( uint256 a, uint256 b ) internal pure returns (bool, uint256) { unchecked { if (a == 0) return (true, 0); uint256 c = a * b; if (c / a != b) return (false, 0); return (true, c); } }
    function tryDiv( uint256 a, uint256 b ) internal pure returns (bool, uint256) { unchecked { if (b == 0) return (false, 0); return (true, a / b); } }
    function tryMod( uint256 a, uint256 b ) internal pure returns (bool, uint256) { unchecked { if (b == 0) return (false, 0); return (true, a % b); } }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { return a + b; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { return a * b; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { return a / b; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { return a % b; }
    function sub( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) { unchecked { require(b <= a, errorMessage); return a - b; } }
    function div( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) { unchecked { require(b > 0, errorMessage); return a / b; } }
    function mod( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) { unchecked { require(b > 0, errorMessage); return a % b; } }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred( address indexed previousOwner, address indexed newOwner );
    constructor() { _transferOwnership(_msgSender()); }
    function owner() public view virtual returns (address) { return _owner; }
    modifier onlyOwner() { require(owner() == _msgSender(), "Ownable: caller is not the owner"); _; }
    function renounceOwnership() public virtual onlyOwner { _transferOwnership(address(0)); }
    function transferOwnership(address newOwner) public virtual onlyOwner { require( newOwner != address(0), "Ownable: new owner is the zero address" ); _transferOwnership(newOwner); }
    function _transferOwnership(address newOwner) internal virtual { address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner); }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) { _name = name_; _symbol = symbol_; }
    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return 18; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf( address account ) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer( address recipient, uint256 amount ) public virtual override returns (bool) { _transfer(_msgSender(), recipient, amount); return true; }
    function allowance( address owner, address spender ) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
    function approve( address spender, uint256 amount ) public virtual override returns (bool) { _approve(_msgSender(), spender, amount); return true; }
    function transferFrom( address sender, address recipient, uint256 amount ) public virtual override returns (bool) { _transfer(sender, recipient, amount); uint256 currentAllowance = _allowances[sender][_msgSender()]; require( currentAllowance >= amount, "ERC20: transfer amount exceeds allowance" ); unchecked { _approve(sender, _msgSender(), currentAllowance - amount); } return true; }
    function increaseAllowance( address spender, uint256 addedValue ) public virtual returns (bool) { _approve( _msgSender(), spender, _allowances[_msgSender()][spender] + addedValue ); return true; }
    function decreaseAllowance( address spender, uint256 subtractedValue ) public virtual returns (bool) { uint256 currentAllowance = _allowances[_msgSender()][spender]; require( currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero" ); unchecked { _approve(_msgSender(), spender, currentAllowance - subtractedValue); } return true; }
    function _transfer( address sender, address recipient, uint256 amount ) internal virtual { require(sender != address(0), "ERC20: transfer from the zero address"); require(recipient != address(0), "ERC20: transfer to the zero address"); _beforeTokenTransfer(sender, recipient, amount); uint256 senderBalance = _balances[sender]; require( senderBalance >= amount, "ERC20: transfer amount exceeds balance" ); unchecked { _balances[sender] = senderBalance - amount; } _balances[recipient] += amount; if (amount > 0) { emit Transfer(sender, recipient, amount); } _afterTokenTransfer(sender, recipient, amount); }
    function _mint(address account, uint256 amount) internal virtual { require(account != address(0), "ERC20: mint to the zero address"); _beforeTokenTransfer(address(0), account, amount); _totalSupply += amount; _balances[account] += amount; emit Transfer(address(0), account, amount); _afterTokenTransfer(address(0), account, amount); }
    function _burn(address account, uint256 amount) internal virtual { require(account != address(0), "ERC20: burn from the zero address"); _beforeTokenTransfer(account, address(0), amount); uint256 accountBalance = _balances[account]; require(accountBalance >= amount, "ERC20: burn amount exceeds balance"); unchecked { _balances[account] = accountBalance - amount; } _totalSupply -= amount; emit Transfer(account, address(0), amount); _afterTokenTransfer(account, address(0), amount); }
    function _approve( address owner, address spender, uint256 amount ) internal virtual { require(owner != address(0), "ERC20: approve from the zero address"); require(spender != address(0), "ERC20: approve to the zero address"); _allowances[owner][spender] = amount; emit Approval(owner, spender, amount); }
    function _beforeTokenTransfer( address from, address to, uint256 amount ) internal virtual {}
    function _afterTokenTransfer( address from, address to, uint256 amount ) internal virtual {}
}

pragma solidity ^0.8.7;

contract ADDC is ERC20, Ownable {
    using SafeMath for uint256;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromLimit;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;

    address payable _marketingWallet = payable(address(0x0D04459dD005Fc793b6EF9e028FBA20Fa928625E));
    address payable _devWallet = payable(address(0x856Eb49e96873271DD98fBD2E1B38f6B34E6c05c));

    bool public swapEnabled;
    bool public isTradingEnabled;
    uint256 public tradingStartBlock = 0;
    uint8 public constant blockCount = 0;

    uint16 public totalBuyFee;
    uint16 public totalSellFee;
    uint16 public marketingBuyFee;
    uint16 public liquidityBuyFee;
    uint16 public marketingSellFee;
    uint16 public liquiditySellFee;

    uint256 public maxBuyAmount = 10**6 * (10**18);
    uint256 public maxWalletAmount = 10**7 * (10**18);

    bool private swapping;

    uint256 public swapTokensAtAmount = 10**5 * (10**18);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    receive() external payable {}

    constructor() ERC20("Anti Doge Doge Club", "ADDC") {
        marketingBuyFee = 9;
        liquidityBuyFee = 1;
        totalBuyFee = marketingBuyFee + liquidityBuyFee;

        marketingSellFee = 23;
        liquiditySellFee = 1;
        totalSellFee = marketingSellFee + liquiditySellFee;

        _connectRouter();

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        swapEnabled = true;

        _mint(owner(), 10**9 * (10**18));
    }

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    function _connectRouter() private {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
    }

    function setBuyFee(uint16 marketing, uint16 liquidity) external onlyOwner {
        require(marketing + liquidity <= 25, "Tax too high");
        marketingBuyFee = marketing;
        liquidityBuyFee = liquidity;

        totalBuyFee = marketing+liquidity;
    }

    function setSellFee(uint16 marketing, uint16 liquidity) external onlyOwner {
        require(marketing + liquidity <= 25, "Tax too high");
        marketingSellFee = marketing;
        liquiditySellFee = liquidity;

        totalSellFee = marketing+liquidity;
    }

    function setMarketingWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Marketing wallet can not be a zero address");

        _marketingWallet = payable(newWallet);
    }

    function setSwapEnabled(bool value) external onlyOwner {
        swapEnabled = value;
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        maxWalletAmount = amount * 10 ** 18;
    }

    function setMaxBuyAmount(uint256 amount) external onlyOwner {
        require(amount >= 100000, "Can't set lower amount, No rugPull");
        maxBuyAmount = amount * 10 ** 18;
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount * 10 ** 18;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Token: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs" );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Token: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setBlacklist(address addr, bool value) external onlyOwner {
        isBlacklisted[addr] = value;
    }

    function enableTrading() external onlyOwner {
        isTradingEnabled = true;
        if (tradingStartBlock == 0) tradingStartBlock = block.number;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Token: Account is already the value of 'excluded'");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromLimit( address account, bool excluded) external onlyOwner {
        isExcludedFromLimit[account] = excluded;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Token: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function claimStuckTokens(address _token) external onlyOwner {
        require(_token != address(this), "Can't remove the native token");
        if (_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function swapAndSendToMarketing(uint256 tokens) private lockTheSwap {
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(tokens);
        uint256 newBalance = address(this).balance.sub(initialBalance);

        uint256 devShare = newBalance.div(2);
        uint256 marketingShare = newBalance - devShare;

        _devWallet.transfer(devShare);
        _marketingWallet.transfer(marketingShare);
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, address(0xdead), block.timestamp);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "Token: transfer from the zero address");
        require(to != address(0), "Token: transfer to the zero address");
        require(!isBlacklisted[from] && !isBlacklisted[to],"Blacklist: Account is blacklisted");
        require(isTradingEnabled || isExcludedFromFees[from],"TradingEnabled: Trading not enabled yet");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= swapTokensAtAmount;

        if (
            swapEnabled &&
            !swapping &&
            from != uniswapV2Pair &&
            overMinimumTokenBalance
        ) {
            contractTokenBalance = swapTokensAtAmount;
            uint16 totalFee = totalBuyFee + totalSellFee;

            uint256 swapTokens = contractTokenBalance.mul(liquidityBuyFee + liquiditySellFee).div(totalFee);
            swapAndLiquify(swapTokens);

            uint256 feeTokens = contractTokenBalance - swapTokens;
            swapAndSendToMarketing(feeTokens);
        }

        bool takeFee = true;

        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees;

            if (automatedMarketMakerPairs[to]) {
                fees = totalSellFee;
            } else if (automatedMarketMakerPairs[from]) {
                fees = totalBuyFee;
            }

            if (!isExcludedFromLimit[from] && !isExcludedFromLimit[to]) {
                if (automatedMarketMakerPairs[from]) {
                    require(amount <= maxBuyAmount, "MaxBuyAmount: Buy exceeds limit");
                    if (block.number < tradingStartBlock + blockCount) {
                        isBlacklisted[to] = true;
                    }
                }

                if (!automatedMarketMakerPairs[to]) {
                    require(balanceOf(to) + amount <= maxWalletAmount, "MaxWalletAmount: Balance exceeds limit");
                }
            }

            uint256 feeAmount = amount.mul(fees).div(100);
            amount = amount.sub(feeAmount);

            super._transfer(from, address(this), feeAmount);
        }

        super._transfer(from, to, amount);
    }
}