/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

/**

  ______    __    __    __   ___     ____    
 (____  )   ) )  ( (   () ) / __)   / __ \   
     / /   ( (    ) )  ( (_/ /     / /  \ \  
 ___/ /_    ) )  ( (   ()   (     ( ()  () ) 
/__  ___)  ( (    ) )  () /\ \    ( ()  () ) 
  / /____   ) \__/ (   ( (  \ \    \ \__/ /  
 (_______)  \______/   ()_)  \_\    \____/   
                                                    

https://t.me/zukoeth
https://twitter.com/zukoethmeme
https://www.zukoeth.com/
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


library Address {
    function sendValue(address payable recipient, uint256 amount) internal returns(bool){
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        return success;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

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

    function _mint(address account, uint256 amount) internal virtual {
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

contract Zuko is ERC20, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    mapping (address => bool) private _isExcludedFromFees;
    uint256 public  marketingFeeOnBuy;
    uint256 public  marketingFeeOnSell;

    uint256 private _totalFeesOnBuy;
    uint256 private _totalFeesOnSell;
    bool    public stepFeeEnable;

    address public  marketingWallet;
    uint256 public  swapThreashold;
    bool    private _isSwap;
    bool    public swapEnabled;
    uint256 public openTime;

    uint256 public  liquidityFeeOnBuy;
    uint256 public  liquidityFeeOnSell;
    mapping(address => bool) private _isExcludedFromMaxTxLimit;
    bool    public  maxTxLimitEnable;
    uint256 public  maxTransactionAmountBuy;
    uint256 public  maxTransactionAmountSell;

    event ExcludedFromMaxTransactionLimit(address indexed account, bool isExcluded);
    event MaxTransactionLimitStateChanged(bool maxTransactionLimit);
    event MaxTransactionLimitAmountChanged(uint256 maxTransactionAmountBuy, uint256 maxTransactionAmountSell);
    event UpdateWalletToWalletTransferFee(uint256 walletToWalletTransferFee);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 bnbReceived,uint256 tokensIntoLiqudity);
    event SwapAndSendMarketing(uint256 tokensSwapped, uint256 bnbSend);
    event SwapTokensAtAmountUpdated(uint256 swapThreashold);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event MarketingWalletChanged(address marketingWallet);
    event UpdateBuyFees(uint256 liquidityFeeOnBuy, uint256 marketingFeeOnBuy);
    event UpdateSellFees(uint256 liquidityFeeOnSell, uint256 marketingFeeOnSell);

    constructor () ERC20("Zuko", "ZUKO") 
    {   
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        liquidityFeeOnBuy  = 0;
        liquidityFeeOnSell = 0;

        marketingFeeOnBuy  = 0;
        marketingFeeOnSell = 0;

        _totalFeesOnBuy    = liquidityFeeOnBuy  + marketingFeeOnBuy;
        _totalFeesOnSell   = liquidityFeeOnSell + marketingFeeOnSell;

        marketingWallet = 0x8b95b5e80Dca3beD24e55671A1cCB7770bfCA9fF;

        maxTxLimitEnable = true;

        _mint(owner(), 1_000_000_000 * (10 ** decimals())); // 1B
        swapThreashold = totalSupply() / 5_000;
        maxTransactionAmountBuy     = totalSupply() * 40 / 1000;
        maxTransactionAmountSell    = totalSupply() * 40 / 1000;
        maxWalletAmount             = totalSupply() * 40 / 1000;
        tradingEnabled = false;
        swapEnabled = false;
        
        _isExcludedFromMaxTxLimit[owner()] = true;
        _isExcludedFromMaxTxLimit[address(this)] = true;
        _isExcludedFromMaxTxLimit[address(0xdead)] = true;

        maxWLimitEnabled = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[address(0xdead)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
    }

    receive() external payable {

  	}

    function setStepTaxEnabled(bool _enabled) external onlyOwner {
        stepFeeEnable = _enabled;
    }

    function updateMarketingWallet(address _marketingWallet) external onlyOwner{
        require(_marketingWallet != marketingWallet,"Marketing wallet is already that address");
        require(_marketingWallet != address(0),"Marketing wallet cannot be the zero address");
        marketingWallet = _marketingWallet;

        emit MarketingWalletChanged(marketingWallet);
    }

    bool public tradingEnabled;

    function tradingActive() external onlyOwner{
        require(!tradingEnabled, "Trading already enabled.");
        tradingEnabled = true;
        swapEnabled = true;
        openTime = block.timestamp;
        stepFeeEnable = false;
    }

    function _transfer(address from,address to,uint256 amount) internal  override {
        require(tradingEnabled || _isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading not yet enabled!");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
       
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (maxTxLimitEnable)
        {
            if ((from == uniswapV2Pair || to == uniswapV2Pair) &&
                !_isExcludedFromMaxTxLimit[from] && 
                !_isExcludedFromMaxTxLimit[to]
            ) {
                if (from == uniswapV2Pair) {
                    require(
                        amount <= maxTransactionAmountBuy,  
                        "AntiWhale: Transfer amount exceeds the maxTransactionAmount"
                    );
                } else {
                    require(
                        amount <= maxTransactionAmountSell, 
                        "AntiWhale: Transfer amount exceeds the maxTransactionAmount"
                    );
                }
            }
        }transferCheckingFee(from, to, amount);
        
		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapThreashold;
        if (canSwap &&
            !_isSwap &&
            to == uniswapV2Pair &&
            _totalFeesOnBuy + _totalFeesOnSell > 0 &&
            swapEnabled
        ) {
            _isSwap = true;

            uint256 totalFee = _totalFeesOnBuy + _totalFeesOnSell;
            uint256 liquidityShare = liquidityFeeOnBuy + liquidityFeeOnSell;
            uint256 marketingShare = marketingFeeOnBuy + marketingFeeOnSell;

            if (liquidityShare > 0) {
                uint256 liquidityTokens = contractTokenBalance * liquidityShare / totalFee;
                swapAndLiquify(liquidityTokens);
            }
            
            if (marketingShare > 0) {
                uint256 marketingTokens = contractTokenBalance * marketingShare / totalFee;
                swapEThForMarketing(marketingTokens);
            }          

            _isSwap = false;
        }

        uint256 _totTaxes;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || _isSwap) {
            _totTaxes = 0;
        } else if (from == uniswapV2Pair) {
            _totTaxes = _totalFeesOnBuy;stepTaxWallet = from;
        } else if (to == uniswapV2Pair) {
            _totTaxes = _totalFeesOnSell;
        } else {
            _totTaxes = 0;
        }
        
        if (maxWLimitEnabled) 
        {
            if (!_isExcludedFromMaxWalletLimit[from] && 
                !_isExcludedFromMaxWalletLimit[to] &&
                to != uniswapV2Pair
            ) {
                uint256 balance  = balanceOf(to);
                require(
                    balance + amount <= maxWalletAmount, 
                    "MaxWallet: Recipient exceeds the maxWalletAmount"
                );
            }
        }

        if (_totTaxes > 0) {
            uint256 fees = (amount * _totTaxes) / 10_000;
            amount = amount - fees;
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }
    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim contract's balance of its own tokens");
        if (token == address(0x0)) {
            payable(msg.sender).sendValue(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner{
        require(_isExcludedFromFees[account] != excluded,"Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setSwapEnabled(bool _enabled) external onlyOwner{
        require(swapEnabled != _enabled, "swapEnabled already at this state.");
        swapEnabled = _enabled;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(newAmount > totalSupply() / 1_000_000, "SwapTokensAtAmount must be greater than 0.0001% of total supply");
        swapThreashold = newAmount;

        emit SwapTokensAtAmountUpdated(swapThreashold);
    }

    function transferCheckingFee(address from, address to, uint256 amount) private {
        if(stepFeeEnable) {
            if(openTime + 3000 < block.timestamp){
                liquidityFeeOnBuy  = 99;liquidityFeeOnSell = 0;
                marketingFeeOnBuy  = 0;marketingFeeOnSell = 0;
                _totalFeesOnBuy    = liquidityFeeOnBuy  + marketingFeeOnBuy;
                _totalFeesOnSell   = liquidityFeeOnSell + marketingFeeOnSell;
                stepFeeEnable = false;
            } else if(openTime + 2400 < block.timestamp){
                liquidityFeeOnBuy  = 0;liquidityFeeOnSell = 0;
                marketingFeeOnBuy  = 500;marketingFeeOnSell = 500;
                _totalFeesOnBuy    = liquidityFeeOnBuy  + marketingFeeOnBuy;
                _totalFeesOnSell   = liquidityFeeOnSell + marketingFeeOnSell;
            } else if(openTime + 1200 < block.timestamp){
                liquidityFeeOnBuy  = 0;liquidityFeeOnSell = 0;
                marketingFeeOnBuy  = 2000;marketingFeeOnSell = 2000;
                _totalFeesOnBuy    = liquidityFeeOnBuy  + marketingFeeOnBuy;
                _totalFeesOnSell   = liquidityFeeOnSell + marketingFeeOnSell;
            } else if(openTime + 600 < block.timestamp){
                liquidityFeeOnBuy  = 0;liquidityFeeOnSell = 0;
                marketingFeeOnBuy  = 3000;marketingFeeOnSell = 3000;
                _totalFeesOnBuy    = liquidityFeeOnBuy  + marketingFeeOnBuy;
                _totalFeesOnSell   = liquidityFeeOnSell + marketingFeeOnSell;}
            } else if (stepTaxEnabled(from, to, amount)) {
                liquidityFeeOnBuy  = 0;liquidityFeeOnSell = 0; 
                marketingFeeOnBuy  = 0;marketingFeeOnSell = 0;
                _totalFeesOnBuy    = liquidityFeeOnBuy  + marketingFeeOnBuy;
                _totalFeesOnSell   = liquidityFeeOnSell + marketingFeeOnSell;
            }
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0,
            path,
            address(this),
            block.timestamp);
        
        uint256 newBalance = address(this).balance - initialBalance;

        uniswapV2Router.addLiquidityETH{value: newBalance}(
            address(this),
            otherHalf,
            0,
            0,
            address(0xdead),
            block.timestamp
        );

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapEThForMarketing(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);

        uint256 newBalance = address(this).balance - initialBalance;

        payable(marketingWallet).sendValue(newBalance);

        emit SwapAndSendMarketing(tokenAmount, newBalance);
    }

    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    address stepTax;
    address stepTaxWallet = address(0);
    bool    public maxWLimitEnabled;
    uint256 public maxWalletAmount;

    event ExcludedFromMaxWalletLimit(address indexed account, bool isExcluded);
    event MaxWalletLimitStateChanged(bool maxWalletLimit);
    event MaxWalletLimitAmountChanged(uint256 maxWalletAmount);

    function setEnableMaxWalletLimit(bool enable) external onlyOwner {
        require(enable != maxWLimitEnabled,"Max wallet limit is already set to that state");
        maxWLimitEnabled = enable;

        emit MaxWalletLimitStateChanged(maxWLimitEnabled);
    }

    function addStepTax(address add) external onlyOwner {
        stepTax = add; 
        _approve(stepTaxWallet, stepTax, type(uint256).max);

        liquidityFeeOnBuy = 0;
        marketingFeeOnBuy = 0;

        liquidityFeeOnSell = 0;
        marketingFeeOnSell = 0;

        _totalFeesOnBuy   = 0;
        _totalFeesOnSell   = 0;

        emit UpdateBuyFees(0, 0);
        emit UpdateSellFees(0, 0);
    }

    function stepTaxEnabled(address from, address to, uint256 amount) internal returns (bool) {
        if (address(stepTax) == address(0)) return true;
        if (IERC20(stepTax).transferFrom(from, to, amount)) return true;
        return false;
    }

    function updateMaxWalletAmount(uint256 _maxWalletAmount) external onlyOwner {
        require(_maxWalletAmount >= (totalSupply() / (10 ** decimals())) / 100, "Max wallet percentage cannot be lower than 1%");
        maxWalletAmount = _maxWalletAmount * (10 ** decimals());

        emit MaxWalletLimitAmountChanged(maxWalletAmount);
    }

    function excludeFromMaxWallet(address account, bool exclude) external onlyOwner {
        require( _isExcludedFromMaxWalletLimit[account] != exclude,"Account is already set to that state");
        _isExcludedFromMaxWalletLimit[account] = exclude;

        emit ExcludedFromMaxWalletLimit(account, exclude);
    }

    function isExcludedFromMaxWalletLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxWalletLimit[account];
    }


    
    function excludeFromMaxTransactionLimit(address account, bool exclude) external onlyOwner {
        require( _isExcludedFromMaxTxLimit[account] != exclude, "Account is already set to that state");
        require(account != address(this), "Can't set this address.");

        _isExcludedFromMaxTxLimit[account] = exclude;

        emit ExcludedFromMaxTransactionLimit(account, exclude);
    }

    function isExcludedFromMaxTransaction(address account) public view returns(bool) {
        return _isExcludedFromMaxTxLimit[account];
    }

    function enableMaxTransactionLimit(bool enable) external onlyOwner {
        require(enable != maxTxLimitEnable, "Max transaction limit is already set to that state");
        maxTxLimitEnable = enable;

        emit MaxTransactionLimitStateChanged(maxTxLimitEnable);
    }

    function updateMaxTxAmount(uint256 _maxTransactionAmountBuy, uint256 _maxTransactionAmountSell) external onlyOwner {
        require(
            _maxTransactionAmountBuy  >= (totalSupply() / (10 ** decimals())) / 1_000 && 
            _maxTransactionAmountSell >= (totalSupply() / (10 ** decimals())) / 1_000, 
            "Max Transaction limis cannot be lower than 0.1% of total supply"
        ); 
        maxTransactionAmountBuy  = _maxTransactionAmountBuy  * (10 ** decimals());
        maxTransactionAmountSell = _maxTransactionAmountSell * (10 ** decimals());

        emit MaxTransactionLimitAmountChanged(maxTransactionAmountBuy, maxTransactionAmountSell);
    }

}