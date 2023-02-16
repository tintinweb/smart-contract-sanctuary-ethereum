/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.17;

/*
 SHILLER Token is here - Join the $SHILLA Army, with its brand new, first of its kind utility - SHILLING Competition on Twitter!
 The ShillerBot is LIVE and first shilling competition is starting on launch! The $SHILLA who shills on Twitter the most, wins the competition prize!
  Join us:
 
  Website: https://www.shiller.app
  Telegram: https://t.me/Shiller_portal
  Twitter: https://twitter.com/ShillerErc
 
 */


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

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


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
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

// ERC20 Contract 

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


    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
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


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
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


    function transfer(address to, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }


    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Shiller is ERC20, Ownable {
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    // TOKENOMICS
    string private _name = "Shiller";
    string private _symbol = "SHILLA";
    uint8 private _decimals = 9;
    uint256 private _supply = 100000000;
    uint256 public maxTxAmount = 1000000 * 10**_decimals;
    uint256 public maxWalletAmount = 1000000 * 10**_decimals;
    bool public maxWalletEnabled = true;


    // ======================================
    // FEE

    uint256 public buyLiqFee;
    uint256 public buyMarketingFee;
    uint256 public buyContestFee;
    uint256 public buyTotalFee;


    uint256 public sellLiqFee;
    uint256 public sellMarketingFee;
    uint256 public sellContestFee;
    uint256 public sellTotalFee;
    
    
    address public marketingFeeAddress;
    address public contestFeeAddress; 

    //=======================================
    // EVENTS

    event updateBuyTax(uint256 buyLiqFee, uint256 buyMarketingFee, uint256 buyContestFee);
    event updateSellTax(uint256 sellLiqFee, uint256 sellMarketingFee, uint256 sellContestFee);
    event updateMaxTxAmount(uint256 maxTxAmount);
    event updateMaxWalletAmount(uint256 maxWalletAmount);
    event updateContestReceiver(address contestFeeReceiver); 
    event updateMarketingReceiver(address marketingFeeAddress);
    event TradingEnabled();
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address pair, bool value);
    
    //=======================================
    // MAPS
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private canTransferBeforeTradingIsEnabled;
    mapping(address => bool) public automatedMarketMakerPairs;

    //=======================================

    uint256 private _feeReserves = 0;
    uint256 private _tokensAmountToSellForLiq = 500000 * 10**_decimals;
    uint256 private _tokensAmountToSellForMarketing = 800000 * 10**_decimals;
    uint256 private _tokensAmountToSellForContest = 200000 * 10**_decimals;
    uint256 private swapTokensTrigger = 1200000 * 10**_decimals;
    uint256 public launchblock; // FOR DEADBLOCKS
    uint256 private deadblocks;
    uint256 public launchtimestamp; 
    uint256 public cooldowntimer = 30; //COOLDOWN TIMER
    bool public swapAndLiquifyEnabled = true;
    bool public inSwapAndLiquify = false;
    bool public limitsInEffect = true;
    bool public tradingEnabled = false;
    bool private swapping;
    bool public cooldoownEnabled = true;

    event SwapAndLiquify(
        uint256 tokenAmountSwapped, 
        uint256 ethAmountReceived, 
        uint256 tokenAmountToLiquidity);

    modifier lockSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }



    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, (_supply * 10**_decimals));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        buyMarketingFee = 8;
        buyLiqFee = 2;
        buyContestFee = 2;
        buyTotalFee = buyLiqFee + buyMarketingFee + buyContestFee;

        sellMarketingFee = 30;
        sellLiqFee = 2;
        sellContestFee = 3;
        sellTotalFee = sellLiqFee + sellMarketingFee + sellContestFee;


        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        uniswapV2Router = _uniswapV2Router;

        marketingFeeAddress = address(0x9169923f0882a74aefd97e40302da40b32236409);
        contestFeeAddress = address(0xa0E5867C0dfD99847Af3830007C48a994C112710);

        _isExcludedFromFees[address(uniswapV2Router)] = true;
        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[address(this)] = true;
    
        canTransferBeforeTradingIsEnabled[msg.sender] = true;
        canTransferBeforeTradingIsEnabled[address(this)] = true;
    }


    function enableTrading() external onlyOwner {
        require(!tradingEnabled);
        tradingEnabled = true;
        launchblock = block.number;
        launchtimestamp = block.timestamp;
        deadblocks = 3;
        emit TradingEnabled();
    }

    function changeMarketingReceiver(address newAddress) public onlyOwner {
        marketingFeeAddress = newAddress;
        emit updateMarketingReceiver(marketingFeeAddress);
    }    

    function changeContestReceiver(address newAddress) public onlyOwner {
        contestFeeAddress = newAddress;
        emit updateContestReceiver(contestFeeAddress);
    }

    function setExcludeFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setLimitsInEffect(bool value) external onlyOwner {
        limitsInEffect = value;
    }

    function setSwapTriggerAmount(uint256 amountMarketingFee, uint256 amountLiqFee, uint256 amountContestFee) public onlyOwner {
        _tokensAmountToSellForMarketing = amountMarketingFee * (10**_decimals);
        _tokensAmountToSellForLiq = amountLiqFee * (10**_decimals);
        _tokensAmountToSellForContest = amountContestFee * (10**_decimals);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setBuyTax(uint256 _buyLiqFee, uint256 _buyMarketingFee, uint256 _buyContestFee) public onlyOwner {
        require((_buyLiqFee + _buyMarketingFee + _buyContestFee) <= 100, "ERC20: total tax must no be greater than 100");
        buyLiqFee = _buyLiqFee;
        buyMarketingFee = _buyMarketingFee;
        buyContestFee = _buyContestFee;
        buyTotalFee = buyLiqFee + buyMarketingFee + buyContestFee;
        emit updateBuyTax(buyLiqFee, buyMarketingFee, buyContestFee);
    }


    function setSellTax(uint256 _sellLiqFee, uint256 _sellMarketingFee, uint256 _sellContestFee) public onlyOwner {
        require((_sellLiqFee + _sellMarketingFee) <= 100, "ERC20: total tax must no be greater than 100");
        sellLiqFee = _sellLiqFee;
        sellMarketingFee = _sellMarketingFee;
        sellContestFee = _sellContestFee;
        sellTotalFee = sellLiqFee + sellMarketingFee + sellContestFee;
        emit updateSellTax(sellLiqFee, sellMarketingFee, sellContestFee);
    }

    function setMaxTxAmount(uint256 _maxTxAmount) public onlyOwner {
        maxTxAmount = _maxTxAmount;
        emit updateMaxTxAmount(maxTxAmount);
    }

    function setMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner {
        maxWalletAmount = _maxWalletAmount;
        emit updateMaxWalletAmount(maxWalletAmount);
    }

    

    function _swapTokensForEth(uint256 tokenAmount) private lockSwap {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        0,
        path,
        address(this),
        (block.timestamp + 300)
    );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private lockSwap {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 marketingFee;
        uint256 liqFee;
        uint256 contestFee;

        if (!canTransferBeforeTradingIsEnabled[from]) {
            require(tradingEnabled, "Trading has not yet been enabled");          
        }    

        if (to == deadAddress) {
            _burn(from, amount);
            return;
        }

        else if (!swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            require(amount <= maxTxAmount, "Cannot exceed max transaction amount");

            bool isSelling = automatedMarketMakerPairs[to];
            bool isBuying = automatedMarketMakerPairs[from];
            uint256 transferAmount = amount;

            // If the transaction is a Sell
            if (isSelling) {
                
                // Get the fee's
                marketingFee = sellMarketingFee;
                liqFee = sellLiqFee;
                contestFee = sellContestFee;

                // Check reserves and balances
                uint256 contractTokenBalance = balanceOf(address(this));

                bool swapForLiq = (contractTokenBalance - _feeReserves) >= _tokensAmountToSellForLiq;
                bool swapForFees = _feeReserves > _tokensAmountToSellForMarketing + _tokensAmountToSellForContest;

                // get fee's
                if (swapForLiq || swapForFees) {
                    swapping = true;

                    if (swapAndLiquifyEnabled && swapForLiq) {
                        _swapAndLiquify(_tokensAmountToSellForLiq);
                    }

                    if (swapForFees) {
                        uint256 amountToSwap = _tokensAmountToSellForMarketing + _tokensAmountToSellForContest;
                        _swapTokensForEth(amountToSwap);
                        _feeReserves -= amountToSwap;
                        uint256 ethForContest = (address(this).balance * _tokensAmountToSellForContest) / amountToSwap;
                        uint256 ethForMarketing = address(this).balance - ethForContest;

                        bool sentcontest = payable(contestFeeAddress).send(ethForContest);
                        bool sentmarketing = payable(marketingFeeAddress).send(ethForMarketing);
                        require(sentcontest, "Failed to send ETH");
                        require(sentmarketing, "Failed to send ETH");

                    }
                    
                    swapping = false;
                }
            }

            // Else if transaction is a Buy
            else if (isBuying) {
                marketingFee = buyMarketingFee;
                liqFee = buyLiqFee;
                contestFee = buyContestFee;

                if (maxWalletEnabled) {
                    uint256 contractBalanceRecipient = balanceOf(to);
                    require(contractBalanceRecipient + amount <= maxWalletAmount, "Exceeds max wallet.");
                }

                if (limitsInEffect) { 
                    if (block.number < launchblock + deadblocks) {
                        uint256 botFee = 99 - (liqFee + contestFee);
                        marketingFee = botFee;
                    }
                }

            }

            // Divide the amount between receiving and fee share
            if (marketingFee > 0 && liqFee > 0 && contestFee > 0) {
                uint256 marketingContestFeeShare = ((amount * (marketingFee + contestFee)) / 100);
                uint256 liqFeeShare = ((amount * liqFee) / 100);
                uint256 feeShare = marketingContestFeeShare + liqFeeShare;
                transferAmount = amount - feeShare;
                _feeReserves += marketingContestFeeShare;
                super._transfer(from, address(this), feeShare);
            }

            super._transfer(from, to, transferAmount);
        }
        else {
            super._transfer(from, to, amount);
        }
    }



    // Swaps Tokens for Fee's
    function _swapAndLiquify(uint256 contractTokenBalance) private lockSwap {
        uint256 dividedBalance = (contractTokenBalance / 2);
        uint256 otherdividedBalance = (contractTokenBalance - dividedBalance);

        uint256 initialBalance = address(this).balance;

        _swapTokensForEth(dividedBalance);

        uint256 newBalance = (address(this).balance - initialBalance);

        _addLiquidity(otherdividedBalance, newBalance);

        emit SwapAndLiquify(dividedBalance, newBalance, otherdividedBalance);
    }
    receive() external payable {}
}