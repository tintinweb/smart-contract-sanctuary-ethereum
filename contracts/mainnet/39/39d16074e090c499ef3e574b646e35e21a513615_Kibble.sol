/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

/**

Join us at -
Twitter: https://twitter.com/Kibble_erc20
telegram: We will announce to the community when listing

TO SUPPORT "Kibble" MOVEMENT
BUY/SELL TAX 5%/10%
 */

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.12;

// ##### Context #####
// This contract is only required for intermediate, library-like contracts.
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// ##### Ownable #####
// Contract module which provides a basic access control mechanism
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Initializes the contract setting the deployer as the initial owner.
    constructor() {
        _transferOwnership(_msgSender());
    }

    // Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    // Transfers ownership of the contract to a new account (`newOwner`).
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    // Transfers ownership of the contract to a new account (`newOwner`).
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// ##### IERC20 #####
interface IERC20 {
    // Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    // Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    // Moves `amount` tokens from the caller's account to `recipient`.
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}. This is zero by default.
    function allowance(address owner, address spender) external view returns (uint256);

    // Sets `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint256 amount) external returns (bool);

    // Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount` is then deducted from the caller's allowance.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    // Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ##### IERC20Metadata #####
// Interface for the optional metadata functions from the ERC20 standard.
interface IERC20Metadata is IERC20 {
    // Returns the name of the token.
    function name() external view returns (string memory);

    // Returns the symbol of the token.
    function symbol() external view returns (string memory);

    // Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

// ##### ERC20 #####
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    // Sets the values for {name} and {symbol}.
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // Returns the name of the token.
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // Returns the symbol of the token, usually a shorter version of the
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // Returns the number of decimals used to get its user representation.
    // For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`).
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    // See {IERC20-totalSupply}.
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    // See {IERC20-balanceOf}.
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    // See {IERC20-transfer}.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // See {IERC20-allowance}.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // See {IERC20-approve}.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // See {IERC20-transferFrom}.
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

    // Atomically increases the allowance granted to `spender` by the caller.
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    // Atomically decreases the allowance granted to `spender` by the caller.
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    // Moves `amount` of tokens from `sender` to `recipient`.
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

    // Creates `amount` tokens and assigns them to `account`, increasing the total supply.
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    // Destroys `amount` tokens from `account`, reducing the total supply.
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

    // Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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

    // Hook that is called before any transfer of tokens. This includes minting and burning.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // Hook that is called after any transfer of tokens. This includes minting and burning.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// ##### IUniswapV2Factory #####
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// ##### IUniswapV2Factory #####
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

    function allowance(address owner, address spender) external view
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

    function getReserves() external view
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

// ##### IUniswapV2Router02 #####
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
    ) external payable
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

// ##### KIBBLE #####
contract Kibble is ERC20, Ownable {
    // Namings
    string private projectName = "Kibble";
    string private tokenName = "Bits";

    // Wallets
    address public devWallet = address(0xb02713140813BE76F9bCAff237D79424b4cEb961);
    address public marketingWallet = address(0x82fc03D981c8252a9B71EC2635EDd2079348c3fF);

    // Tokens
    uint256 public tokensForDev;
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;

    // Buy fee percents
    uint256 public buyTotalFees;
    uint256 public buyDevFee = 0;
    uint256 public buyMarketingFee = 5;
    uint256 public buyLiquidityFee = 0;
    
    // Sell fee percents
    uint256 public sellTotalFees;
    uint256 public sellDevFee = 0;
    uint256 public sellMarketingFee = 10;
    uint256 public sellLiquidityFee = 0;
    
    // Limits
    uint256 public maxTransactionAmount = 5000000 * (10 ** decimals()); // 0.5% from total supply maxTransactionAmountTxn;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletAmount = 15000000 * (10 ** decimals()); // 1.5% from total supply maxWalletAmount;

    // Restrictions
    bool public limitsEnabled = true;
    bool public tradingEnabled = false;
    bool public swapEnabled = false;

    // UniswapV2Router02
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
     
    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    // Etc. 
    bool private swapping;
   
   // Exlcude from fees and max transaction amount
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    // Exclude from fees
    event ExcludeFromFees(address indexed account, bool isExcluded);

    // Set automated market maker pair
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    // Swap and liquify
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20(projectName, tokenName) {
        // Uniswap
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAMMPair(address(uniswapV2Pair), true);
        
        // Total supply
        uint256 totalSupply = 1000000000 * (10 ** decimals());

        // Swap Tokens At Amount
        swapTokensAtAmount = (totalSupply * 10) / 10000; // 0.1% swap wallet
        
        // Buy fees
        buyTotalFees = buyDevFee + buyMarketingFee + buyLiquidityFee;
        
        // Sell fees
        sellTotalFees = sellDevFee + sellMarketingFee + sellLiquidityFee;

        // Exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);

        // _mint is an internal function in ERC20.sol that is only called here, and CANNOT be called ever again.
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // Enable trading (once enabled, can never be turned off)
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        swapEnabled = true;
    }

    function disableLimits() external onlyOwner {
        limitsEnabled = false;
    }

    function enableLimits() external onlyOwner {
        limitsEnabled = true;
    }

    // Disable transfer delay (once enabled, can never be turned off)
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    // Change the minimum amount of tokens to sell from fees
    function setSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(newAmount >= (totalSupply() * 1) / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= (totalSupply() * 5) / 1000, "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }

    // Update maximum transaction amount
    function setMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 1) / 1000) / (10 ** decimals()), "Cannot set maxTransactionAmount lower than 0.1%");
        maxTransactionAmount = newNum * (10**18);
    }

    // Update maximum wallet amount
    function setMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 5) / 1000) / (10 ** decimals()), "Cannot set maxWallet lower than 0.5%");
        maxWalletAmount = newNum * (10**18);
    }
	
    // Exclude from max transaction
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner
    {
        isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // Disable contract sales if absolutely necessary (emergency use only)
    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    // Update buy fees
    function setBuyFees(
		uint256 _devFee,
        uint256 _marketingFee,
        uint256 _liquidityFee
    ) external onlyOwner {
		require((_devFee + _marketingFee + _liquidityFee) <= 10, "Max buy fee is <= 10%");
		buyDevFee = _devFee;
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyDevFee + buyMarketingFee + buyLiquidityFee;
     }

    // Update sell fees
    function setSellFees(
		uint256 _devFee,
        uint256 _marketingFee,
        uint256 _liquidityFee
    ) external onlyOwner {
		require((_devFee + _marketingFee + _liquidityFee) <= 10, "Max sell fee is <= 10%");
		sellDevFee = _devFee;
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellDevFee + sellMarketingFee + sellLiquidityFee;
    }

    // Exclude from fees
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // Market Maker Pair
    function setAMMPair(address pair, bool value) public onlyOwner
    {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAMMPair(pair, value);
    }

    function _setAMMPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // Transfer
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

        if (limitsEnabled) {
            if (from != owner() && to != owner() && to != address(0) && to != deadAddress && !swapping ) {
                if (!tradingEnabled) {
                    require(isExcludedFromFees[from] || isExcludedFromFees[to], "Trading is not active.");
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (automatedMarketMakerPairs[from] && !isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWalletAmount, "Max wallet exceeded");
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !isExcludedMaxTransactionAmount[from]
                ) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                } else if (!isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWalletAmount, "Max wallet exceeded");
                }
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount * sellTotalFees / 100;      
                tokensForDev += (fees * sellDevFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount * buyTotalFees / 100;
				tokensForDev += (fees * buyDevFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;  
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    // Swap tokens for Eth.
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

    // Add Liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            devWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForDev + tokensForMarketing + tokensForLiquidity;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance - initialETHBalance;

        uint256 ethForDev = ethBalance * tokensForDev / totalTokensToSwap;
        uint256 ethForMarketing = ethBalance * tokensForMarketing / totalTokensToSwap;
        uint256 ethForLiquidity = ethBalance - ethForDev - ethForMarketing;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;

        (success, ) = address(devWallet).call{value: ethForDev}("");
        (success, ) = address(marketingWallet).call{value: ethForMarketing}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }
    }
}