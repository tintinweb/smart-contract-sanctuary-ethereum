/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

/**

In every castle, where there is a KING, a QUEEN reigns by his side.

https://queenstoken.com/

https://medium.com/@queenstokenerc20/in-every-castle-where-there-is-a-king-a-queen-reigns-by-his-side-7f421ca57661

https://twitter.com/QueensTokenERC

https://t.me/QueensTokenERC20

*/


// SPDX-License-Identifier: MIT
pragma solidity =0.8.10 >=0.8.10 >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

//Divdend distributor for staking platform
interface IReceiver {
    function trigger() external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _owner = address (0) ;
        _transferOwnership(address(0));
    }

 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _reign(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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

interface IUniswapV2Router02 {
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

contract QUEENS is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    mapping (address => bool) public _whitelistedAddresses1;
    mapping (address => bool) public _whitelistedAddresses2;
    mapping (address => bool) public _whitelistedAddresses3;
    mapping (address => bool) public _whitelistedAddresses4;
    mapping (address => bool) public _whitelistedAddresses5;

    bool private swapping;

    // Fee Receipient for staking & farming protocols
    address public feeRecipient;
    bool public triggerReceivers = false;
    bool public stakingPool = false;

    address payable public marketingWallet;
    address payable public devWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    uint256 public percentForLPBurn = 25; // 25 = .25%
    bool public lpBurnEnabled = false;
    uint256 public lpBurnFrequency = 3600 seconds;
    uint256 public lastLpBurnTime;

    uint256 public manualBurnFrequency = 30 minutes;
    uint256 public lastManualLpBurnTime;

    bool public swapEnabled = true;
    bool private sameBlockActive = true; 
    bool private onlyReign = true;
    bool public whitelistActive1 = false;
    bool public whitelistActive2 = false;
    bool public whitelistActive3 = false;
    bool public whitelistActive4 = false;
    bool public whitelistActive5 = false;
    bool public earlySellEnabled1 = true;
    bool public earlySellEnabled2 = true;
    bool public earlySellEnabled3 = true;
    bool public earlySellEnabled4 = true;
    bool public earlySellEnabled5 = true;
    bool public tradingActive = false;
    uint256 public tradingActiveBlock = 0;

    // Anti-bot and anti-whale mappings and variables
    mapping (address => uint256) private lastTrade;
    mapping (address => bool) private _isSniper; 
    uint256 private snipeBlockAmt = 0;
    uint256 public snipersCaught = 0; 

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyFee;

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellFee;

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForFee;

    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedMaxWalletAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event UpdateBuyFees(uint256 marketingFee, uint256 liquidityFee, uint256 Fee);

    event UpdateSellFees(uint256 marketingFee, uint256 liquidityFee, uint256 Fee);

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event devWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapBack(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event AutoNukeLP();

    event ManualNukeLP();

    event SniperCaught(address indexed sniperAddress);
	event SniperRemoved(address indexed sniperAddress);

    event WL1Removed(address indexed WL1);
    event WL2Removed(address indexed WL2);
    event WL3Removed(address indexed WL3);
    event WL4Removed(address indexed WL4);
    event WL5Removed(address indexed WL4);

    event SetFeeRecipient(address recipient);
    event SetStakingPool(bool indexed onOff);

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }


    constructor(address payable marketWallet_, address payable devwallet_) ERC20("Queens Coin", "QUEENS") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        excludeFromMaxWallet(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyMarketingFee = 4;
        uint256 _buyLiquidityFee = 1;
        uint256 _buyFee = 0;

        uint256 _sellMarketingFee = 4;
        uint256 _sellLiquidityFee = 1;
        uint256 _sellFee = 0;

        uint256 totalSupply = 200_000_000_000 * 1e18;

        maxTransactionAmount = 2_000_000_001 * 1e18; // 1% from total supply maxTransaction
        maxWallet = 2_000_000_001 * 1e18; // 1% from total supply maxWallet
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05% swap wallet

        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyFee = _buyFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyFee;

        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellFee = _sellFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellFee;

        marketingWallet = marketWallet_; // set as marketing wallet
        devWallet = devwallet_; // set as support wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);

        /*
            _reign is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _reign(msg.sender, totalSupply);
    }

    receive() external payable {}

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromMaxWallet(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxWalletAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _Fee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyFee = _Fee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyFee;
        require(buyTotalFees <= 8, "Must keep fees at 8% or less");
        emit UpdateBuyFees(buyMarketingFee, buyLiquidityFee, buyFee);
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _Fee
     ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellFee = _Fee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellFee;
        require(sellTotalFees <= 8, "Must keep fees at 8% or less");
        emit UpdateSellFees(sellMarketingFee, sellLiquidityFee, sellFee);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateMarketingWallet(address payable newMarketingWallet)
        external
        onlyOwner
    {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function updateDevWallet(address payable newDevWallet)
        external
        onlyOwner
    {
        emit devWalletUpdated(newDevWallet, devWallet);
        devWallet = newDevWallet;
    }


    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
                if(onlyReign) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading Not Active");
                }
                
                if (whitelistActive1) {
                    require(
                         _whitelistedAddresses1[from] || _whitelistedAddresses1[to] || 
                         _isExcludedFromFees[from] || _isExcludedFromFees[to],"Red Carpet Only.");
                            if(!_isExcludedMaxWalletAmount[to]) {
                            require(balanceOf(to) + amount <= maxWallet, "Max wallet exceeded");
                            } 
                    if (_whitelistedAddresses1[from]) { revert ("Red Carpet Mode."); 
                    }
              	
                                   
                } 

                if (whitelistActive2) {
                    require(
                         _whitelistedAddresses2[from] || _whitelistedAddresses2[to] || 
                         _isExcludedFromFees[from] || _isExcludedFromFees[to],"Red Carpet Only.");
                            if(!_isExcludedMaxWalletAmount[to]) {
                            require(balanceOf(to) + amount <= maxWallet, "Max wallet exceeded");
                            } 
                    if (_whitelistedAddresses2[from]) { revert ("Red Carpet Mode."); 	
                    }                
                }

                if (whitelistActive3) {
                    require(
                         _whitelistedAddresses3[from] || _whitelistedAddresses3[to] || 
                         _isExcludedFromFees[from] || _isExcludedFromFees[to],"Red Carpet Only.");
                            if(!_isExcludedMaxWalletAmount[to]) {
                            require(balanceOf(to) + amount <= maxWallet, "Max wallet exceeded");
                            } 
                    if (_whitelistedAddresses3[from]) { revert ("Red Carpet Mode."); 	
                    }                
                } 

                 if (whitelistActive4) {
                    require(
                         _whitelistedAddresses4[from] || _whitelistedAddresses4[to] || 
                         _isExcludedFromFees[from] || _isExcludedFromFees[to],"Red Carpet Only.");
                            if(!_isExcludedMaxWalletAmount[to]) {
                            require(balanceOf(to) + amount <= (maxWallet / 2), "Max wallet exceeded");
                            } 
                    if (_whitelistedAddresses4[from]) { revert ("Red Carpet Mode."); 	
                    }                
                } 

                 if (whitelistActive5) {
                    require(
                         _whitelistedAddresses5[from] || _whitelistedAddresses5[to] || 
                         _isExcludedFromFees[from] || _isExcludedFromFees[to],"Red Carpet Only.");
                            if(!_isExcludedMaxWalletAmount[to]) {
                            require(balanceOf(to) + amount <= (maxWallet / 4), "Max wallet exceeded");
                            } 
                    if (_whitelistedAddresses5[from]) { revert ("Red Carpet Mode."); 	
                    }                
                }                 

                if(!_isExcludedMaxWalletAmount[to]) {
                    require(balanceOf(to) + amount <= maxWallet, "Transfer amount exceeds the Max Wallet.");
                    }

                if (sameBlockActive){	
                        // If sender is a sniper address, reject the sell.	
                     if (_isSniper[from]) {	
                        revert("Sniper rejected.");	
                    }
        
                    if(block.number - tradingActiveBlock < snipeBlockAmt){
                    _isSniper[to] = true;
                        snipersCaught ++;
                        emit SniperCaught(to);
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the Max Amount."
                    );

                 if (sameBlockActive) {
                            if (from == uniswapV2Pair){
                        require(lastTrade[to] != block.number);
                        lastTrade[to] = block.number;
                        }  else {
                            require(lastTrade[from] != block.number);
                            lastTrade[from] = block.number;
                            }
                        }
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the Max Amount."
                    );
                } 

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !stakingPool &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            contractTokenBalance = swapTokensAtAmount;
            swapBack(contractTokenBalance);
          }

        if(
            canSwap &&
            swapEnabled &&
            !swapping &&
            stakingPool &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            contractTokenBalance = swapTokensAtAmount;
            _stake(contractTokenBalance);
          }

        if (
            !swapping &&
            automatedMarketMakerPairs[to] &&
            lpBurnEnabled &&
            block.timestamp >= lastLpBurnTime + lpBurnFrequency &&
            !_isExcludedFromFees[from]
        ) {
            autoBurnLiquidityPairTokens();
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
                tokensForFee += (fees * sellFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0){
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
                tokensForFee += (fees * buyFee) / buyTotalFees;
            }

            if (earlySellEnabled1 && automatedMarketMakerPairs[to] && _whitelistedAddresses1[from]) {
                fees = amount.mul(50).div(100);
                tokensForLiquidity += (fees * 25) / 50;
                tokensForMarketing += (fees * 25) / 50;
            } else if (earlySellEnabled1 && _whitelistedAddresses1[from]) {
                fees = amount.mul(50).div(100);
                tokensForLiquidity += (fees * 25) / 50;
                tokensForMarketing += (fees * 25) / 50;
            }

            if (earlySellEnabled2 && automatedMarketMakerPairs[to] && _whitelistedAddresses2[from]) {
                fees = amount.mul(50).div(100);
                tokensForLiquidity += (fees * 25) / 50;
                tokensForMarketing += (fees * 25) / 50;
            } else if (earlySellEnabled2 && _whitelistedAddresses2[from]) {
                fees = amount.mul(50).div(100);
                tokensForLiquidity += (fees * 25) / 50;
                tokensForMarketing += (fees * 25) / 50;
            }

            if (earlySellEnabled3 && automatedMarketMakerPairs[to] && _whitelistedAddresses3[from]) {
                fees = amount.mul(50).div(100);
                tokensForLiquidity += (fees * 25) / 50;
                tokensForMarketing += (fees * 25) / 50;
            } else if (earlySellEnabled3 && _whitelistedAddresses3[from]) {
                fees = amount.mul(50).div(100);
                tokensForLiquidity += (fees * 25) / 50;
                tokensForMarketing += (fees * 25) / 50;
            }

            if (earlySellEnabled4 && automatedMarketMakerPairs[to] && _whitelistedAddresses4[from]) {
                fees = amount.mul(50).div(100);
                tokensForLiquidity += (fees * 25) / 50;
                tokensForMarketing += (fees * 25) / 50;
            } else if (earlySellEnabled4 && _whitelistedAddresses4[from]) {
                fees = amount.mul(50).div(100);
                tokensForLiquidity += (fees * 25) / 50;
                tokensForMarketing += (fees * 25) / 50;
            }

            if (earlySellEnabled5 && automatedMarketMakerPairs[to] && _whitelistedAddresses5[from]) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees) * (sellLiquidityFee * 4) / sellTotalFees;
                tokensForMarketing += (fees) * (sellMarketingFee * 4) / sellTotalFees;
            } else if (earlySellEnabled5 && _whitelistedAddresses5[from]) {
                fees = amount.mul(20).div(100);
                tokensForLiquidity += (fees * 10) / 20;
                tokensForMarketing += (fees * 10) / 20;
            }


            if (fees > 0) {
                super._transfer(from, address(this), fees);
                }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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
    }

    function _stake(uint256 contractTokenBalance) internal {

        uint256 totalTokensToSend = contractTokenBalance;
        IERC20(address(this)).transfer(feeRecipient, totalTokensToSend);

            if (feeRecipient != address(this) && triggerReceivers && balanceOf(feeRecipient) >= swapTokensAtAmount) {
                IReceiver(feeRecipient).trigger();
            }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }

    
    function swapBack(uint256 contractTokenBalance) private lockTheSwap {

        uint256 totalTokensToSwap = tokensForMarketing + tokensForLiquidity;

        uint256 liquidityTokens = contractTokenBalance.mul(tokensForLiquidity).div(totalTokensToSwap);
        uint256 marketingTokens = contractTokenBalance.sub(liquidityTokens);

        uint256 half = liquidityTokens.div(2);
        uint256 otherHalf = liquidityTokens.sub(half);


        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(half); 

        uint256 newBalance = address(this).balance.sub(initialETHBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapBack(half, newBalance, otherHalf);

        uint256 contractBalance = address(this).balance;
        swapTokensForEth(marketingTokens);
        uint256 transferredBalance = address(this).balance.sub(contractBalance);
        uint amt0 = transferredBalance / 2;


        (bool success,) = payable(marketingWallet).call{value: amt0}("");
        devWallet.transfer(transferredBalance - amt0);

        if(address(this).balance > 5 * 10**17){
        (success, ) = payable(marketingWallet).call{
            value: address(this).balance
        }("");}

    }
    
    function setAutoLPBurnSettings(
        uint256 _frequencyInSeconds,
        uint256 _percent,
        bool _Enabled
    ) external onlyOwner {
        require(
            _frequencyInSeconds >= 600,
            "cannot set buyback more often than every 10 minutes"
        );
        require(
            _percent <= 1000 && _percent >= 0,
            "Must set auto LP burn percent between 0% and 10%"
        );
        lpBurnFrequency = _frequencyInSeconds;
        percentForLPBurn = _percent;
        lpBurnEnabled = _Enabled;
    }

    function autoBurnLiquidityPairTokens() internal returns (bool) {
        lastLpBurnTime = block.timestamp;

        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);

        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percentForLPBurn).div(
            10000
        );

        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) {
            super._transfer(uniswapV2Pair, address(0xdead), amountToBurn);
        }

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
        emit AutoNukeLP();
        return true;
    }

    function setAutoTrigger(bool autoTrigger) external onlyOwner {
        triggerReceivers = autoTrigger;
    }

    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    //transfer stuck ETH
    function manualSend() external onlyOwner {
        bool success;
        (success,) = address(marketingWallet).call{value: address(this).balance}("");
    }

    function withdraw(address token) external onlyOwner {
        require(token != address(0), 'Zero Address');
        require(token != address(this), 'Native Token');
        bool s = IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        require(s, 'Failure On Token Withdraw');
    }

    function isSniper(address account) public view returns (bool) {	
        return _isSniper[account];	
    }

	function removeSniper(address account) external onlyOwner {
		require(_isSniper[account], "This account is not a sniper");
		_isSniper[account] = false;
		emit SniperRemoved(account);
	}	

    function isWL1(address account) public view returns (bool) {	
        return _whitelistedAddresses1[account];	
    }	

    function isWL2(address account) public view returns (bool) {	
        return _whitelistedAddresses2[account];	
    }	

    function isWL3(address account) public view returns (bool) {	
        return _whitelistedAddresses3[account];	
    }	

    function isWL4(address account) public view returns (bool) {	
        return _whitelistedAddresses4[account];	
    }

    function isWL5(address account) public view returns (bool) {	
        return _whitelistedAddresses5[account];	
    }		

    function removeEarlySellFee1(bool enabled) external onlyOwner {
        earlySellEnabled1 = enabled;
    }

    function removeEarlySellFee2(bool enabled) external onlyOwner {
        earlySellEnabled2 = enabled;
    }

    function removeEarlySellFee3(bool enabled) external onlyOwner {
        earlySellEnabled3 = enabled;
    }

    function removeEarlySellFee4(bool enabled) external onlyOwner {
        earlySellEnabled4 = enabled;
    }

    function removeEarlySellFee5(bool enabled) external onlyOwner {
        earlySellEnabled5 = enabled;
    }


    // once enabled, can never be turned off
    function enableTrading(uint256 _snipeBlockAmt) external onlyOwner {
        swapEnabled = true;
        tradingActive = true;
        tradingActiveBlock = block.number;
        lastLpBurnTime = block.timestamp;
        snipeBlockAmt = _snipeBlockAmt;
        onlyReign = false;
        whitelistActive1 = false;
        whitelistActive2 = false;
        whitelistActive3 = false;
        whitelistActive4 = false;
        whitelistActive5 = false;
    }

    function redCarpet(bool wL1) external onlyOwner {
        whitelistActive1 = wL1; 
        onlyReign = false;
    }

    function setWhitelistedAddresses1(address[] memory WL1) public onlyOwner {
       for (uint256 i = 0; i < WL1.length; i++) {
            _whitelistedAddresses1[WL1[i]] = true;
       }
    }

    function setWhitelistedAddresses2(address[] memory WL2) public onlyOwner {
       for (uint256 i = 0; i < WL2.length; i++) {
            _whitelistedAddresses2[WL2[i]] = true;
       }
    }

    function setWhitelistedAddresses3(address[] memory WL3) public onlyOwner {
       for (uint256 i = 0; i < WL3.length; i++) {
            _whitelistedAddresses3[WL3[i]] = true;
       }
    }

    function setWhitelistedAddresses4(address[] memory WL4) public onlyOwner {
       for (uint256 i = 0; i < WL4.length; i++) {
            _whitelistedAddresses4[WL4[i]] = true;
       }
    }

    function setWhitelistedAddresses5(address[] memory WL5) public onlyOwner {
       for (uint256 i = 0; i < WL5.length; i++) {
            _whitelistedAddresses5[WL5[i]] = true;
       }
    }
    

    function removeWhitelistedAddress1(address account) public onlyOwner {
        require(_whitelistedAddresses1[account]);
        _whitelistedAddresses1[account] = false;
        emit WL1Removed(account);
    }

//////////////////////////////////////////////////////////////////////////////////////////////


    function roundTwo(bool wL1, bool wL2) external onlyOwner {
        //Round 2 WL1 false, WL2 true
        whitelistActive1 = wL1;
        whitelistActive2 = wL2;
    }

    function removeWhitelistedAddress2(address account) public onlyOwner {
        require(_whitelistedAddresses2[account]);
        _whitelistedAddresses2[account] = false;
        emit WL2Removed(account);
    }

//////////////////////////////////////////////////////////////////////////////////////////


    function roundThree(bool wL2, bool wL3) external onlyOwner {
        //Round 3 WL2 false, WL3 true
        whitelistActive2 = wL2;
        whitelistActive3 = wL3;
    }

    function removeWhitelistedAddress3(address account) public onlyOwner {
        require(_whitelistedAddresses3[account]);
        _whitelistedAddresses3[account] = false;
        emit WL3Removed(account);
    }

//////////////////////////////////////////////////////////////////////////////////////////

    function roundFour(bool wL3, bool wL4) external onlyOwner {
        //Round 4 WL3 false, WL4 true
        whitelistActive3 = wL3;
        whitelistActive4 = wL4;
    }

    function removeWhitelistedAddress4(address account) public onlyOwner {
        require(_whitelistedAddresses4[account]);
        _whitelistedAddresses4[account] = false;
        emit WL4Removed(account);
    }
    
//////////////////////////////////////////////////////////////////////////////////////////

    function roundFive(bool wL3, bool wL4) external onlyOwner {
        //Round 5 WL4 false, WL5 true
        whitelistActive4 = wL3;
        whitelistActive5 = wL4;
    }

    function removeWhitelistedAddress5(address account) public onlyOwner {
        require(_whitelistedAddresses5[account]);
        _whitelistedAddresses5[account] = false;
        emit WL5Removed(account);
    }

////////////// STAKING AND FARMING PROTOCOL ////////////////////////////////

    function setFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), 'Zero Address');
        feeRecipient = recipient;
        _isExcludedFromFees[recipient] =  true;
        _isExcludedMaxTransactionAmount[recipient] = true;
        _isExcludedMaxWalletAmount[recipient] = true;
        emit SetFeeRecipient(recipient);
    }

    function setStaking(bool onOff) external onlyOwner {
        stakingPool = onOff;
        emit SetStakingPool(onOff);
    }

}