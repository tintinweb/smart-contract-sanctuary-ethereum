/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

/*
Teh Degen Rehab X is Opening Soon!
$DRX JUST ANOTHER DEGEN MEME TOKEN!
*/
pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

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
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
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

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased cannot be below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
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

contract DegenRehabX is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable router;
    address public immutable uniswapV2Pair;

    // addresses
    address private marketingWallet;
    address private rehabWallet;

    // limits
    uint256 private maxBuyAmount;
    uint256 private maxSellAmount;
    uint256 private maxWalletAmount;

    uint256 private thresholdSwapAmount;

    bool private isTrading = false;
    bool public swapEnabled = false;
    bool public isSwapping;

    struct Fees {
        uint256 buyTotalFees;
        uint256 buyMarketingFee;
        uint256 buyRehabFee;
        uint256 buyLiquidityFee;
        uint256 sellTotalFees;
        uint256 sellMarketingFee;
        uint256 sellRehabFee;
        uint256 sellLiquidityFee;
    }

    Fees public _fees =
        Fees({
            buyTotalFees: 0,
            buyMarketingFee: 0,
            buyRehabFee: 0,
            buyLiquidityFee: 0,
            sellTotalFees: 0,
            sellMarketingFee: 0,
            sellRehabFee: 0,
            sellLiquidityFee: 0
        });

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForRehab;
    uint256 private antiSnipe;

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedMaxWalletAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public marketPair;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);

    constructor() ERC20(unicode"DegenRehabX", unicode"DRX") {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        _isExcludedMaxTransactionAmount[address(router)] = true;
        _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;
        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;

        _isExcludedMaxWalletAmount[owner()] = true;
        _isExcludedMaxWalletAmount[address(this)] = true;
        _isExcludedMaxWalletAmount[address(uniswapV2Pair)] = true;

        marketPair[address(uniswapV2Pair)] = true;

        approve(address(router), type(uint256).max);
        uint256 totalSupply = 1000000 * 1e9;

        maxBuyAmount = (totalSupply * 12) / 1000; // 1.2% maxBuy
        maxSellAmount = (totalSupply * 12) / 1000; // 1.2% maxSell
        maxWalletAmount = (totalSupply * 24) / 1000; // 2.4% maxWallet
        thresholdSwapAmount = (totalSupply * 5) / 10000; // 0.05% swap wallet

        _fees.buyMarketingFee = 15;
        _fees.buyLiquidityFee = 0;
        _fees.buyRehabFee = 0;
        _fees.buyTotalFees =
            _fees.buyMarketingFee +
            _fees.buyLiquidityFee +
            _fees.buyRehabFee;

        _fees.sellMarketingFee = 25;
        _fees.sellLiquidityFee = 0;
        _fees.sellRehabFee = 0;
        _fees.sellTotalFees =
            _fees.sellMarketingFee +
            _fees.sellLiquidityFee +
            _fees.sellRehabFee;

        marketingWallet = address(msg.sender);
        rehabWallet = address(msg.sender);

        // exclude from paying fees or having max transaction amount

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function openTrading() external onlyOwner {
        isTrading = true;
        swapEnabled = true;
        antiSnipe = block.number + 2;
    }

    function removeLimits() external onlyOwner {
        maxWalletAmount = totalSupply();
        maxSellAmount = totalSupply();
        maxBuyAmount = totalSupply();
    }

    function toggleSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateFees(
        uint256 _marketingFeeBuy,
        uint256 _liquidityFeeBuy,
        uint256 _rehabFeeBuy,
        uint256 _marketingFeeSell,
        uint256 _liquidityFeeSell,
        uint256 _rehabFeeSell
    ) external onlyOwner {
        _fees.buyMarketingFee = _marketingFeeBuy;
        _fees.buyLiquidityFee = _liquidityFeeBuy;
        _fees.buyRehabFee = _rehabFeeBuy;
        _fees.buyTotalFees =
            _fees.buyMarketingFee +
            _fees.buyLiquidityFee +
            _fees.buyRehabFee;
        require(_fees.buyTotalFees <= 10, "Must keep buy fees at 10% or less");
        _fees.sellMarketingFee = _marketingFeeSell;
        _fees.sellLiquidityFee = _liquidityFeeSell;
        _fees.sellRehabFee = _rehabFeeSell;
        _fees.sellTotalFees =
            _fees.sellMarketingFee +
            _fees.sellLiquidityFee +
            _fees.sellRehabFee;
        require(
            _fees.sellTotalFees <= 69, "Must keep sell fees at 69% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function excludeFromWalletLimit(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedMaxWalletAmount[account] = excluded;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setMarketPair(address pair, bool value) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from marketPair"
        );
        marketPair[pair] = value;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        if (sender != owner() && recipient != owner() && !isSwapping) {
            if (!isTrading) {
                require(
                    _isExcludedFromFees[sender] ||
                        _isExcludedFromFees[recipient],
                    "Trading is not active."
                );
            }
            if (
                marketPair[sender] &&
                !_isExcludedMaxTransactionAmount[recipient]
            ) {
                require(
                    amount <= maxBuyAmount,
                    "Buy transfer amount exceeds the maxTransactionAmount."
                );
            } else if (
                marketPair[recipient] &&
                !_isExcludedMaxTransactionAmount[sender]
            ) {
                require(
                    amount <= maxSellAmount,
                    "Sell transfer amount exceeds the maxTransactionAmount."
                );
            }

            if (!_isExcludedMaxWalletAmount[recipient]) {
                require(
                    amount + balanceOf(recipient) <= maxWalletAmount,
                    "Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= thresholdSwapAmount;

        if (
            canSwap &&
            swapEnabled &&
            !isSwapping &&
            marketPair[recipient] &&
            !_isExcludedFromFees[sender] &&
            !_isExcludedFromFees[recipient]
        ) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }

        bool takeFee = !isSwapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            uint256 fees = 0;
            if (block.number < antiSnipe) {
                fees = amount.mul(99).div(100);
                tokensForMarketing += (fees * 90) / 99;
                tokensForRehab += (fees * 9) / 99;
            } else if (marketPair[recipient] && _fees.sellTotalFees > 0) {
                fees = amount.mul(_fees.sellTotalFees).div(100);
                tokensForLiquidity +=
                    (fees * _fees.sellLiquidityFee) /
                    _fees.sellTotalFees;
                tokensForMarketing +=
                    (fees * _fees.sellMarketingFee) /
                    _fees.sellTotalFees;
                tokensForRehab += (fees * _fees.sellRehabFee) / _fees.sellTotalFees;
            }
            // on buy
            else if (marketPair[sender] && _fees.buyTotalFees > 0) {
                fees = amount.mul(_fees.buyTotalFees).div(100);
                tokensForLiquidity +=
                    (fees * _fees.buyLiquidityFee) /
                    _fees.buyTotalFees;
                tokensForMarketing +=
                    (fees * _fees.buyMarketingFee) /
                    _fees.buyTotalFees;
                tokensForRehab += (fees * _fees.buyRehabFee) / _fees.buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(sender, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(sender, recipient, amount);
    }

    function swapTokensForEth(uint256 tAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 toSwap = tokensForLiquidity + tokensForMarketing + tokensForRehab;
        bool success;

        if (contractTokenBalance == 0 || toSwap == 0) {
            return;
        }

        if (contractTokenBalance > thresholdSwapAmount * 20) {
            contractTokenBalance = thresholdSwapAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractTokenBalance * tokensForLiquidity) /
            toSwap /
            2;
        uint256 amountToSwapForETH = contractTokenBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 newBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = newBalance.mul(tokensForMarketing).div(
            toSwap
        );
        uint256 ethForRehab = newBalance.mul(tokensForRehab).div(toSwap);
        uint256 ethForLiquidity = newBalance - (ethForMarketing + ethForRehab);

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForRehab = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity);
        }

        (success, ) = address(rehabWallet).call{
            value: (address(this).balance - ethForMarketing)
        }("");
        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }
}