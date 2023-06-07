/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

/**
*/
// SPDX-License-Identifier: MIT
/**

Twitter: https://twitter.com/CashApp
Web: https://cash.app/
TG: https://t.me/cashapp_portal

**/

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = address(_msgSender());
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract CashApp is Ownable, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromWalletHoldingLimit;
    mapping(address => bool) private _isAutomaticMarketMaker;
    mapping(address => bool) private _isAccountLimited;

    uint256 public _decimals = 18;
    uint256 public _totalSupply = 100 * 10**6 * 10**_decimals;
    string private _name = "CashApp";
    string private _symbol = "CashApp";

    address public immutable DeadWalletAddress =
        0x000000000000000000000000000000000000dEaD;
    address payable public MarketingWalletAddress;

    uint256 public _BuyingMarketingFee = 10;

    uint256 public _SellingMarketingFee = 30;

    uint256 internal feeDenominator = 100;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool internal inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public numTokensSellToAddToLiquidity = (_totalSupply * 150) / 10**4;
    uint256 public _maxWalletHoldingLimit = (_totalSupply * 2) / 10**2;

    event MaxWalletHoldingAmountUpdated(uint256 updatedMaxWalletHoldingAmount);
    event AutomaticMarketMakerPairUpdated(address account, bool status);
    event BuyingTaxFeeUpdated(uint256 TaxFees);
    event SellingTaxFeeUpdated(uint256 TaxFees);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ETHReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _balances[owner()] = _totalSupply;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        //DeployerWallet
        MarketingWalletAddress = payable(address(msg.sender));
        //exclude owner and this contract from fee and Wallet holding Limits
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromWalletHoldingLimit[owner()] = true;
        _isExcludedFromWalletHoldingLimit[uniswapV2Pair] = true;
        _isExcludedFromWalletHoldingLimit[address(this)] = true;
        _isAutomaticMarketMaker[uniswapV2Pair] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "IERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function ExcludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function IncludeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function IsExcludedFromTax(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromWalletLimit(address WalletAddress)
        external
        view
        returns (bool)
    {
        return _isExcludedFromWalletHoldingLimit[WalletAddress];
    }

    function excludeFromMaxWalletHoldingLimit(address account)
        external
        onlyOwner
    {
        _isExcludedFromWalletHoldingLimit[account] = true;
    }

    function includeInMaxWalletHoldingLimit(address account)
        external
        onlyOwner
    {
        require(
            account != uniswapV2Pair,
            "You can't play with Liquidity pair address"
        );
        _isExcludedFromWalletHoldingLimit[account] = false;
    }

    function UpdateAccountLimition(address account, bool status)
        external
        onlyOwner
    {
        _isAccountLimited[account] = status;
    }

    function isAccountLimited(address account) external view returns (bool) {
        return _isAccountLimited[account];
    }

    function UpdateWallets(address payable newMarketingWallet)
        external
        onlyOwner
    {
        require(newMarketingWallet != address(0), "You can't set zero address");
        MarketingWalletAddress = newMarketingWallet;
    }

    function UpdateBuyingTaxFees(uint256 newMarketingFee) external onlyOwner {
        _BuyingMarketingFee = newMarketingFee;
        emit BuyingTaxFeeUpdated(_BuyingMarketingFee);
    }

    function UpdateSellingTaxFees(uint256 newMarketingFee) external onlyOwner {
        _SellingMarketingFee = newMarketingFee;
        emit SellingTaxFeeUpdated(_SellingMarketingFee);
    }

    function UpdateNoOfTokensSellToGetReward(uint256 thresholdValue)
        external
        onlyOwner
    {
        numTokensSellToAddToLiquidity = thresholdValue * 10**_decimals;
        emit MinTokensBeforeSwapUpdated(numTokensSellToAddToLiquidity);
    }

    function removeAllLimitsAndTaxes() external onlyOwner {
        _maxWalletHoldingLimit = (_totalSupply * 100) / 10**2;
        _BuyingMarketingFee = 0;
        _SellingMarketingFee = 0;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "IERC20: transfer amount exceeds allowance"
        );
        return true;
    }

    // To receive BNB from PancakeswapV2 when swapping
    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "IERC20: transfer from the zero address");
        require(
            recipient != address(0),
            "IERC20: transfer to the zero address"
        );
        require(
            !_isAccountLimited[sender] && !_isAccountLimited[recipient],
            "Sorry your account is limiited"
        );
        require(_balances[sender] >= amount, "You don't have enough balance");

        if (
            !_isExcludedFromWalletHoldingLimit[recipient] && sender != owner()
        ) {
            require(
                balanceOf(recipient) + amount <= _maxWalletHoldingLimit,
                "Wallet Holding limit exceeded"
            );
        }

        uint256 totalTax = 0;

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            totalTax = 0;
        } else {
            if (_isAutomaticMarketMaker[recipient]) {
                totalTax = (amount * (_SellingMarketingFee)) / (feeDenominator);
            } else if (_isAutomaticMarketMaker[sender]) {
                totalTax = (amount * (_BuyingMarketingFee)) / (feeDenominator);
            } else {
                totalTax = 0;
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            !inSwapAndLiquify &&
            recipient == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            balanceOf(uniswapV2Pair) > numTokensSellToAddToLiquidity
        ) {
            if (overMinTokenBalance) {
                contractTokenBalance = numTokensSellToAddToLiquidity;

                if (_SellingMarketingFee > 0) {
                    swapTokens(contractTokenBalance);
                }
            }
        }

        uint256 amountReceived = amount - (totalTax);
        _balances[address(this)] += totalTax;
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] += amountReceived;

        if (totalTax > 0) {
            emit Transfer(sender, address(this), totalTax);
        }
        emit Transfer(sender, recipient, amountReceived);
    }

    function swapTokens(uint256 _contractTokenBalance) private lockTheSwap {
        uint256 combineFee = _SellingMarketingFee;
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(_contractTokenBalance);
        uint256 transferredBalance = address(this).balance - (initialBalance);
        uint256 MarketingBalance = (transferredBalance *
            (_SellingMarketingFee)) / (combineFee);
        if (MarketingBalance > 0) {
            transferToAddressETH(MarketingWalletAddress, MarketingBalance);
        }

        if (address(this).balance > 0) {
            MarketingWalletAddress.transfer(address(this).balance);
        }
    }

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> wETH
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
}