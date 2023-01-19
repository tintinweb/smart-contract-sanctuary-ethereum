/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*

🧙‍♂️ Swap anonymously 🪄 💨💸

Break the 🔗 between sending and receiving wallets. Privacy is security.

Website: houdiniswap.com
Support: @HoudiniSwapSupport_bot
Whitepaper: houdiniswap.com/whitepaper
Twitter: twitter.com/houdiniswap
TG: t.me/houdiniswap

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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

    function owner() public view virtual returns (address) {
        return _owner;
    }

}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

}

interface IERC20Metadata is IERC20 {

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

}

contract ERC20 is IERC20, IERC20Metadata {

    string private _name;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;


    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
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

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
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

contract Poof is ERC20, Ownable {

    mapping(address => bool) public isExcludedMaxTransaction;
    uint256 public tokensForLiquidity;
    IUniswapV2Router02 public immutable router;
    bool public limitsInEffect = false;
    address public marketingWallet;
    address public immutable rampPair;
    uint256 public maxTransactionAmount;

    uint256 public buyTotalFees;
    uint256 public sellLiquidityFee;
    address public LPRecipient;
    mapping(address => bool) private ifNoFee;
    bool private swapping;
    uint256 public feeDenominator = 1000;
    uint256 public buyLiquidityFee;
    uint256 public buyMarketingFee;

    uint256 public tokensForMarketing;
    uint256 public sellMarketingFee;
    uint256 public sellTotalFees;
    uint256 public maxWallet;

    constructor(address router_, address marketingWallet_, address LPRecipient_) ERC20("Houdini Swap", "POOF") {

        router = IUniswapV2Router02(router_);

        rampPair = IUniswapV2Factory(
                router.factory()
        ).createPair(
            address(this),
            router.WETH()
        );

        LPRecipient = LPRecipient_;
        isExcludedMaxTransaction[address(router)] = true;
        isExcludedMaxTransaction[address(rampPair)] = true;
        marketingWallet = marketingWallet_;

        uint256 totalSupply = 100_000_000 * 1e18;

        uint256 _sellLiquidityFee = 20;
        uint256 _sellMarketingFee = 40;
        uint256 _buyLiquidityFee = 20;
        uint256 _buyMarketingFee = 40;

        sellMarketingFee = _sellMarketingFee;
        ifNoFee[address(0xdead)] = true;

        sellLiquidityFee = _sellLiquidityFee;
        ifNoFee[address(this)] = true;
        buyMarketingFee = _buyMarketingFee;
        isExcludedMaxTransaction[address(0xdead)] = true;
        isExcludedMaxTransaction[address(this)] = true;
        buyLiquidityFee = _buyLiquidityFee;

        buyTotalFees = buyLiquidityFee + buyMarketingFee;
        sellTotalFees = sellLiquidityFee + sellMarketingFee;

        maxTransactionAmount = totalSupply;
        maxWallet = totalSupply;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(address(this), totalSupply);
    }

    function swapBack() internal {
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing;
        uint256 contractBalance = balanceOf(address(this));

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            // Reset to 0
            contractBalance = 0;
            totalTokensToSwap = 0;
            return;
        }

        uint256 liquidity = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance - liquidity;
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(amountToSwapForETH);
        uint256 ethBalance = (address(this).balance) - initialETHBalance;
        uint256 ethForMarketing = ethBalance * tokensForMarketing / totalTokensToSwap;
        uint256 ethForLiquidity = ethBalance - ethForMarketing;
        tokensForMarketing = 0;
        tokensForLiquidity = 0;

        if (liquidity > 0 && ethForLiquidity > 0) {
            _addAMMLiquidity(liquidity, ethForLiquidity, LPRecipient);
        }

        if (address(this).balance > 0) {
            bool success;
            (success, ) = address(marketingWallet).call{value: address(this).balance}("");
        }
    }

    function addInitialLiquidityAndStartTrading() external payable onlyOwner {
        uint256 tokensToAdd = 62_000 * 10**18;

        address teamWallet = address(0x555Db6EF47c43150CcadfBFb5FA65D1FEdD606f9);
        address investorWallet = address(0xf97F1457c450fEEEb83DC7a3c779dD9De25cA252);
        address presaleWallet = address(0xF9eF4BBdB08C314e6ec1de2441456eFA565A98F8);
        address liquidityReserveWallet = address(0xA3ee6132e7D8Fe8b6f62712A8C84243d7d0Bf70E);

        _addAMMLiquidity(tokensToAdd, msg.value, owner());

        super._transfer(address(this), teamWallet, 5_000_000 * 10**18);
        super._transfer(address(this), investorWallet, 5_000_000 * 10**18);
        super._transfer(address(this), presaleWallet, 30_000_000 * 10**18);
        super._transfer(address(this), liquidityReserveWallet, 59_938_000 * 10**18);
    }

    receive() external payable {}

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
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
                    from == rampPair &&
                    !isExcludedMaxTransaction[to]
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
                    to == rampPair &&
                    !isExcludedMaxTransaction[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "!maxTransactionAmount."
                    );
                } else if (!isExcludedMaxTransaction[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "!maxWallet"
                    );
                }
            }
        }

        if (
            !swapping &&
            from != rampPair &&
            !ifNoFee[from] &&
            !ifNoFee[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (ifNoFee[from] || ifNoFee[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            if (to == rampPair && sellTotalFees > 0) {
                fees = amount * sellTotalFees / feeDenominator;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
            }

            else if (from == rampPair && buyTotalFees > 0) {
                fees = amount * buyTotalFees / feeDenominator;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function _addAMMLiquidity(uint256 tokenAmount, uint256 ethAmount, address tokenRecipient) internal {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            tokenRecipient,
            block.timestamp
        );
    }

    function getBackStuckETH() external {
        if (address(this).balance > 0) {
            bool success;
            (success, ) = address(marketingWallet).call{value: address(this).balance}("");
            require(success);
        }
    }

}