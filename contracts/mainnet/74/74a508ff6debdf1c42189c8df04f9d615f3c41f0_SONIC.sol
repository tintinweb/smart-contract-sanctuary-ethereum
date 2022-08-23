/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

/**
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool); 
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBEP20Metadata is IBEP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract BEP20 is Context, IBEP20, IBEP20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _totalSupply;
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

    function transferFrom(address sender, address recipient, uint256 amount 
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount,
                "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue,
                "BEP20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount,"BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r,
                    bytes32 s) external;

    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out,
               uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1,
                                                  uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired,
                          uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline)
                          external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin,
                             uint256 amountETHMin, address to, uint256 deadline)
                             external payable returns (uint256 amountToken, uint256 amountETH,
                             uint256 liquidity);

    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin,
                             uint256 amountBMin, address to, uint256 deadline) 
                             external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin,
                                uint256 amountETHMin, address to, uint256 deadline) 
                                external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(address tokenA, address tokenB, uint256 liquidity,
                                       uint256 amountAMin, uint256 amountBMin, address to,
                                       uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) 
                                       external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(address token, uint256 liquidity, uint256 amountTokenMin,
                                          uint256 amountETHMin, address to, uint256 deadline,
                                          bool approveMax, uint8 v, bytes32 r, bytes32 s) 
                                          external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path,
                                      address to, uint256 deadline) 
                                      external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path,
                                      address to, uint256 deadline) 
                                      external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to,
                                   uint256 deadline) 
                                   external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path,
                                   address to, uint256 deadline) 
                                   external returns (uint256[] memory amounts);

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path,
                                   address to, uint256 deadline) 
                                   external returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to,
                                   uint256 deadline) 
                                   external payable returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) 
                   external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) 
                          external pure returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) 
                         external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
                           external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
                          external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint256 liquidity,
        uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) 
        external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint256 liquidity,
        uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax,
        uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin,
        address[] calldata path, address to, uint256 deadline) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin,
        address[] calldata path, address to, uint256 deadline) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin,
        address[] calldata path, address to, uint256 deadline) external;
}

contract SONIC is BEP20, Ownable { // 
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    bool private swapping;
    bool public tradingEnabled = false;

    uint256 internal sellAmount = 0;
    uint256 internal buyAmount = 0;

    uint256 private totalSellFees;
    uint256 private totalBuyFees;

    address payable public marketingWallet; //
    address payable public devWallet; //

    uint256 public maxWallet;
    bool public maxWalletEnabled = true;
    uint256 public swapTokensAtAmount;
    uint256 public sellMarketingFees;
    uint256 public sellBurnFee;
    uint256 public buyMarketingFees;
    uint256 public buyBurnFee;
    uint256 public buyDevFee;
    uint256 public sellDevFee;

    bool public swapAndLiquifyEnabled = true;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private canTransferBeforeTradingIsEnabled;

    bool public limitsInEffect = false; 
    uint256 private gasPriceLimit = 7 * 1 gwei; // MAX GWEI
    mapping(address => uint256) private _holderLastTransferBlock; // FOR 1TX PER BLOCK
    mapping(address => uint256) private _holderLastTransferTimestamp; // FOR COOLDOWN
    uint256 public launchblock; // FOR DEADBLOCKS
    uint256 public launchtimestamp; // FOR LAUNCH TIMESTAMP 
    uint256 public cooldowntimer = 5; // DEFAULT COOLDOWN TIMER

    event EnableSwapAndLiquify(bool enabled);
    event SetPreSaleWallet(address wallet);
    event updateMarketingWallet(address wallet);
    event updateDevWallet(address wallet);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event TradingEnabled();

    event UpdateFees(uint256 sellMarketingFees, uint256 sellBurnFee, uint256 buyMarketingFees,
                     uint256 buyBurnFee, uint256 buyDevFee, uint256 sellDevFee);

    event Airdrop(address holder, uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 opAmount, bool success);

    constructor() BEP20("SONIC", "SONIC") { // 
        marketingWallet = payable(0xE53DB15f908afD63481F123B89e4cE8E08f1D02c); // 
        devWallet = payable(0xE53DB15f908afD63481F123B89e4cE8E08f1D02c); // 
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        //INITIAL FEE VALUES HERE
        buyMarketingFees = 2;
        sellMarketingFees = 8;
        buyBurnFee = 0;
        sellBurnFee = 0;
        buyDevFee = 0;
        sellDevFee = 0;

        // TOTAL BUY AND TOTAL SELL FEE CALCS
        totalBuyFees = buyMarketingFees.add(buyDevFee);
        totalSellFees = sellMarketingFees.add(sellDevFee);

        uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this), uniswapV2Router.WETH());

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[marketingWallet] = true;

        uint256 totalSupply = (1_000_000_000) * (10**18); // TOTAL SUPPLY IS SET HERE
        _mint(owner(), totalSupply); // only time internal mint function is ever called is to create supply
        maxWallet = _totalSupply / 50; // 2%
        swapTokensAtAmount = _totalSupply / 100; // 2%;
        canTransferBeforeTradingIsEnabled[owner()] = true;
        canTransferBeforeTradingIsEnabled[address(this)] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingEnabled);
        tradingEnabled = true;
        launchblock = block.number;
        launchtimestamp = block.timestamp;
        emit TradingEnabled();
    }
    
    function setMarketingWallet(address wallet) external onlyOwner {
        _isExcludedFromFees[wallet] = true;
        marketingWallet = payable(wallet);
        emit updateMarketingWallet(wallet);
    }

    function setDevWallet(address wallet) external onlyOwner {
        _isExcludedFromFees[wallet] = true;
        devWallet = payable(wallet);
        emit updateDevWallet(wallet);
    }
    
    function setExcludeFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setCanTransferBefore(address wallet, bool enable) external onlyOwner {
        canTransferBeforeTradingIsEnabled[wallet] = enable;
    }

    function setLimitsInEffect(bool value) external onlyOwner {
        limitsInEffect = value;
    }

    function setMaxWalletEnabled(bool value) external onlyOwner {
        maxWalletEnabled = value;
    }

    function setcooldowntimer(uint256 value) external onlyOwner {
        require(value <= 300, "cooldown timer cannot exceed 5 minutes");
        cooldowntimer = value;
    }

    
    function setmaxWallet(uint256 value) external onlyOwner {
        value = value * (10**18);
        require(value >= _totalSupply / 100, "max wallet cannot be set to less than 1%");
        maxWallet = value;
    }

    // TAKES ALL BNB FROM THE CONTRACT ADDRESS AND SENDS IT TO OWNERS WALLET
    function Sweep() external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB);
    }

    function setSwapTriggerAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount * (10**18);
    }

    function enableSwapAndLiquify(bool enabled) public onlyOwner {
        require(swapAndLiquifyEnabled != enabled);
        swapAndLiquifyEnabled = enabled;
        emit EnableSwapAndLiquify(enabled);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // THIS IS THE ONE YOU USE TO TRASNFER OWNER IF U EVER DO
    function transferAdmin(address newOwner) public onlyOwner {
        _isExcludedFromFees[newOwner] = true;
        canTransferBeforeTradingIsEnabled[newOwner] = true;
        transferOwnership(newOwner);
    }

    function updateFees(uint256 marketingBuy, uint256 marketingSell, uint256 burnBuy,
                        uint256 burnSell, uint256 devBuy, uint256 devSell) public onlyOwner {

        buyMarketingFees = marketingBuy;
        buyBurnFee = burnBuy;
        sellMarketingFees = marketingSell;
        sellBurnFee = burnSell;
        buyDevFee = devBuy;
        sellDevFee = devSell;

        totalSellFees = sellMarketingFees.add(sellDevFee);
        totalBuyFees = buyMarketingFees.add(buyDevFee);

        // 
        require(totalSellFees <= 99 && totalBuyFees <= 99, "t");

        emit UpdateFees(sellMarketingFees, sellBurnFee, sellDevFee, buyMarketingFees,
                        buyBurnFee, buyDevFee);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "IBEP20: transfer from the zero address");
        require(to != address(0), "IBEP20: transfer to the zero address");

        uint256 marketingFees;
        uint256 burnFee;
        uint256 devFee;

        if (!canTransferBeforeTradingIsEnabled[from]) {
            require(tradingEnabled, "Trading has not yet been enabled");          
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        } 
        
        else if (
            !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]
        ) {
            bool isSelling = automatedMarketMakerPairs[to];
            if (isSelling) {
                marketingFees = sellMarketingFees;
                burnFee = sellBurnFee;
                devFee = sellDevFee;

                if (limitsInEffect) {
                require(block.timestamp >= _holderLastTransferTimestamp[tx.origin] + cooldowntimer,
                        "cooldown period active");
                _holderLastTransferTimestamp[tx.origin] = block.timestamp;
                }
            } 
            
            else {
                marketingFees = buyMarketingFees;
                burnFee = buyBurnFee;
                devFee = buyDevFee;

                if (limitsInEffect) {
                require(block.number > launchblock + 0,"you shall not pass");
                require(tx.gasprice <= gasPriceLimit,"Gas price exceeds limit.");
                require(_holderLastTransferBlock[tx.origin] != block.number,"Too many TX in block");
                require(block.timestamp >= _holderLastTransferTimestamp[tx.origin] + cooldowntimer,
                        "cooldown period active");
                _holderLastTransferBlock[tx.origin] = block.number;
                _holderLastTransferTimestamp[tx.origin] = block.timestamp;
            }

            if (maxWalletEnabled) {
            uint256 contractBalanceRecipient = balanceOf(to);
            require(contractBalanceRecipient + amount <= maxWallet,
                    "Exceeds maximum wallet token amount." );
            }
            }

            uint256 totalFees = marketingFees.add(devFee);

            uint256 contractTokenBalance = balanceOf(address(this));

            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if (canSwap && !automatedMarketMakerPairs[from]) {
                swapping = true;
             
                uint256 swapBalance = swapTokensAtAmount;
                swapAndSendDividends(swapBalance);
                buyAmount = 0;
                sellAmount = 0;
                swapping = false;
            }

            uint256 fees = amount.mul(totalFees).div(100);
            uint256 burntokens = amount.mul(burnFee).div(100);

            amount = amount.sub(fees + burntokens);

            if (isSelling) {
                sellAmount = sellAmount.add(fees);
            } else {
                buyAmount = buyAmount.add(fees);
            }

            super._transfer(from, address(this), fees);

            if (burntokens > 0) {
                super._transfer(from, DEAD, burntokens);
                _totalSupply = _totalSupply.sub(burntokens);
            }
           
        }

        super._transfer(from, to, amount);
        
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function forceSwapAndSendDividends(uint256 tokens) public onlyOwner {
        tokens = tokens * (10**18);
        uint256 totalAmount = buyAmount.add(sellAmount);
        uint256 fromBuy = tokens.mul(buyAmount).div(totalAmount);
        uint256 fromSell = tokens.mul(sellAmount).div(totalAmount);

        swapAndSendDividends(tokens);

        buyAmount = buyAmount.sub(fromBuy);
        sellAmount = sellAmount.sub(fromSell);
    }

    // TAX PAYOUT CODE 
    function swapAndSendDividends(uint256 tokens) private {
        if (tokens == 0) {
            return;
        }
        swapTokensForEth(tokens);

        bool success = true;
        bool successOp1 = true;
        
        uint256 _marketDevTotal = sellMarketingFees.add(sellDevFee) + buyMarketingFees.add(buyDevFee);

        uint256 feePortions;
        if (_marketDevTotal > 0) {
            feePortions = address(this).balance.div(_marketDevTotal);
        }
        uint256 marketingPayout = buyMarketingFees.add(sellMarketingFees) * feePortions;
        uint256 devPayout = buyDevFee.add(sellDevFee) * feePortions;
        
        if (marketingPayout > 0) {
            (success, ) = address(marketingWallet).call{value: marketingPayout}("");
        }
        
        if (devPayout > 0) {
            (successOp1, ) = address(devWallet).call{value: devPayout}("");
        }

        emit SendDividends(
            marketingPayout,
            success && successOp1
        );
    }

    function airdropToWallets(
        address[] memory airdropWallets,
        uint256[] memory amount
    ) external onlyOwner {
        require(airdropWallets.length == amount.length, "Arrays must be the same length");
        require(airdropWallets.length <= 200, "Wallets list length must be <= 200");
        for (uint256 i = 0; i < airdropWallets.length; i++) {
            address wallet = airdropWallets[i];
            uint256 airdropAmount = amount[i] * (10**18);
            super._transfer(msg.sender, wallet, airdropAmount);
        }
    }
}