/**
 *Submitted for verification at Etherscan.io on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*

- Fabergé Egg - The worlds rarest egg

Socials:
- Telegram: https://t.me/fabergeth
- Twitter: https://twitter.com/fabergeeggs69

- Final Taxes will be 4/4
*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
}

interface IERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);

}

interface IERC20Metadata is IERC20 {

    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

}

contract ERC20 is IERC20, IERC20Metadata {

    string private _symbol;
    string private _name;


    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount greater than allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from zero address");
        require(recipient != address(0), "ERC20: transfer to zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount greater than balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract FabergeEgg is ERC20, Ownable {

    address public LiquidityTokenReceivoor;
    address public marketingReceivoor;
    address public devReceivoor;

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    uint256 public buyMarketingFee;
    uint256 public buyDevFee;
    uint256 public buyLiquidityFee;

    uint256 public sellMarketingFee;
    uint256 public sellDevFee;
    uint256 public sellLiquidityFee;

    uint256 public tokensForMarketing;
    uint256 public tokensForDev;
    uint256 public tokensForLiquidity;

    IUniswapV2Router02 public router;
    address public liquidityPair;

    mapping(address => bool) public isAMM;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;

    mapping(address => bool) private isExcludedFromFee;
    mapping(address => bool) public isExcludedFromWalletLimits;

    uint256 public feeDenominator = 1000;
    
    bool private swapping;
    bool public limitsInEffect = true;

    
    bool maxSellFeeSet = false;
    bool maxBuyFeeSet = false;
    uint256 maxSellFee;
    uint256 maxBuyFee;

    constructor(
        address router_,
        address LiquidityTokenReceivoor_,
        address marketingReceivoor_,
        address devReceivoor_
    ) ERC20("Faberge Egg", "FEGG") Ownable(msg.sender) {

        LiquidityTokenReceivoor = LiquidityTokenReceivoor_;
        devReceivoor = devReceivoor_;
        marketingReceivoor = marketingReceivoor_;

        router = IUniswapV2Router02(router_);

        liquidityPair = IUniswapV2Factory(
            router.factory()
        ).createPair(
            address(this),
            router.WETH()
        );

        isAMM[liquidityPair] = true;

        isExcludedFromWalletLimits[address(liquidityPair)] = true;
        isExcludedFromWalletLimits[address(router)] = true;        
        isExcludedFromWalletLimits[address(this)] = true;
        isExcludedFromWalletLimits[address(0xdead)] = true;
        isExcludedFromWalletLimits[msg.sender] = true;
        isExcludedFromWalletLimits[LiquidityTokenReceivoor] = true;

        uint256 totalSupply = 6_900_000 * 1e18;
        
        
        buyMarketingFee = 130;
        buyDevFee = 100;
        buyLiquidityFee = 20;

        sellMarketingFee = 550;
        sellDevFee = 420;
        sellLiquidityFee = 20;

        buyTotalFees = buyMarketingFee + buyDevFee + buyLiquidityFee;
        sellTotalFees = sellMarketingFee + sellDevFee + sellLiquidityFee;

        isExcludedFromFee[address(0xdead)] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[LiquidityTokenReceivoor] = true;

        
        maxTransactionAmount = totalSupply * 20 / 1000;
        maxWallet = totalSupply * 20 / 1000;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function setBuyFees(uint256 marketingFee, uint256 devFee, uint256 liquidityFee) external onlyOwner {
        buyMarketingFee = marketingFee;
        buyDevFee = devFee;
        buyLiquidityFee = liquidityFee;

        buyTotalFees = buyMarketingFee + buyDevFee + buyLiquidityFee;

        if (maxBuyFeeSet) {
            require(buyTotalFees <= maxBuyFee);
        }

    }

    function setSellFees(uint256 marketingFee, uint256 devFee, uint256 liquidityFee) external onlyOwner {
        sellMarketingFee = marketingFee;
        sellDevFee = devFee;
        sellLiquidityFee = liquidityFee;

        sellTotalFees = sellMarketingFee + sellDevFee + sellLiquidityFee;

        if (maxSellFeeSet) {
            require(sellTotalFees <= maxSellFee);
        }

    }

    function setLimits(uint256 maxTransactionAmount_, uint256 maxWallet_) external onlyOwner {
        maxTransactionAmount = maxTransactionAmount_;
        maxWallet = maxWallet_;
    }

    function removeLimits() external onlyOwner {
        require(limitsInEffect);
        limitsInEffect = false;
    }

    function setLiquidityTokenReceivoor(address newReceiver) external onlyOwner {
        require(LiquidityTokenReceivoor != newReceiver);
        LiquidityTokenReceivoor = newReceiver;
    }

    function setMarketingReceivoor(address newReceiver) external onlyOwner {
        require(marketingReceivoor != newReceiver);
        marketingReceivoor = newReceiver;
    }

    function setDevReceivoor(address newReceiver) external onlyOwner {
        require(devReceivoor != newReceiver);
        devReceivoor = newReceiver;
    }

    function setAMM(address ammAddress, bool isAMM_) external onlyOwner {
        isAMM[ammAddress] = isAMM_;
    }

    function setWalletExcludedFromLimits(address wallet, bool isExcluded) external onlyOwner {
        isExcludedFromWalletLimits[wallet] = isExcluded;
    }

    function setWalletExcludedFromFees(address wallet, bool isExcluded) external onlyOwner {
        isExcludedFromFee[wallet] = isExcluded;
    }

    function setRouter(address router_) external onlyOwner {
        router = IUniswapV2Router02(router_);
    }

    function setLiquidityPair(address pairAddress) external onlyOwner {
        liquidityPair = pairAddress;
    }

    function enableMaxSellFeeLimit(uint256 limit) external onlyOwner {
        require(limit <= feeDenominator && limit < maxSellFee);
        maxSellFee = limit;
        maxSellFeeSet = true;
    }

    function enableMaxBuyFeeLimit(uint256 limit) external onlyOwner {
        require(limit <= feeDenominator && limit < maxBuyFee);
        maxBuyFee = limit;
        maxBuyFeeSet = true;
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

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0xdead) &&
                !swapping
            ) {

                if (
                    isAMM[from] &&
                    !isExcludedFromWalletLimits[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "!maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "!maxWallet"
                    );
                }

                else if (
                    isAMM[to] &&
                    !isExcludedFromWalletLimits[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "!maxTransactionAmount."
                    );
                } else if (!isExcludedFromWalletLimits[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "!maxWallet"
                    );
                }

            }
        }

        bool takeFee = !swapping;

        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (takeFee) {

            uint256 fees = 0;

            if (isAMM[to] && sellTotalFees > 0) {
                uint256 newTokensForDev = amount * sellDevFee / feeDenominator;
                uint256 newTokensForMarketing = amount * sellMarketingFee / feeDenominator;
                uint256 newTokensForLiquidity = amount * sellLiquidityFee / feeDenominator;

                fees = newTokensForDev + newTokensForMarketing + newTokensForLiquidity;

                tokensForDev += newTokensForDev;
                tokensForMarketing += newTokensForMarketing;
                tokensForLiquidity += newTokensForLiquidity;
            }

            else if (isAMM[from] && buyTotalFees > 0) {
                uint256 newTokensForDev = amount * buyDevFee / feeDenominator;
                uint256 newTokensForMarketing = amount * buyMarketingFee / feeDenominator;
                uint256 newTokensForLiquidity = amount * buyLiquidityFee / feeDenominator;

                fees = newTokensForDev + newTokensForMarketing + newTokensForLiquidity;

                tokensForDev += newTokensForDev;
                tokensForMarketing += newTokensForMarketing;
                tokensForLiquidity += newTokensForLiquidity;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }

        if (
            !swapping &&
            from != liquidityPair &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }


        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() internal {
        if (tokensForLiquidity + tokensForDev + tokensForMarketing == 0) {
            return;
        }

        uint256 liquidity = tokensForLiquidity / 2;
        uint256 amountToSwapForETH = tokensForDev + tokensForMarketing + (tokensForLiquidity - liquidity);
        swapTokensForEth(amountToSwapForETH);

        uint256 ethForLiquidity = address(this).balance * (tokensForLiquidity - liquidity) / amountToSwapForETH;

        if (liquidity > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidity, ethForLiquidity);
        }

        if (tokensForMarketing + tokensForDev > 0) {
            uint256 remainingBalance = address(this).balance;
            uint256 amountForMarketing = remainingBalance * tokensForMarketing / (tokensForMarketing + tokensForDev);
            uint256 amountForDev = remainingBalance - amountForMarketing;
            
            if (amountForMarketing > 0) {
                marketingReceivoor.call{value: amountForMarketing}("");    
            }

            if (amountForDev > 0) {
                devReceivoor.call{value: amountForDev}("");    
            }
        }

        tokensForLiquidity = 0;
        tokensForDev = 0;
        tokensForMarketing = 0;
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            LiquidityTokenReceivoor,
            block.timestamp
        );
    }

}