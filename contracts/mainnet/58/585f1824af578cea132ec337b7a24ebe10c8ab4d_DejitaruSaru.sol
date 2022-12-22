/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*

t.me/DejitaruSaru

Monkey See, Monkey do...

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function transfer(address recipient, uint256 amount) external returns (bool);



    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface IERC20Metadata is IERC20 {

    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

}

contract ERC20 is IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _symbol;
    string private _name;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
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

contract DejitaruSaru is ERC20, Ownable {

    uint256 public buyLiquidityFee;
    uint256 public tokensForLiquidity;
    uint256 public sellTotalFees;
    uint256 public maxWallet;
    uint256 public maxTransactionAmount;
    address public immutable liquidityPair;
    mapping(address => bool) private feeExcluded;
    address public treasuryWallet;
    bool private swapping;
    uint256 public feeDenominator = 1000;
    uint256 public buyTreasuryFee;

    uint256 public tokensForTreasury;
    uint256 public buyTotalFees;
    mapping(address => bool) public isExcludedMaxTransactionAmount;

    address public LPTokenRecipient;


    bool public limitsInEffect = true;
    IUniswapV2Router02 public immutable router;

    uint256 public sellTreasuryFee;
    uint256 public sellLiquidityFee;

    constructor(address router_, address treasuryWallet_, address LPTokenRecipient_) ERC20("Dejitaru Saru", "DEJITARUSARU") {

        router = IUniswapV2Router02(router_);

        isExcludedMaxTransactionAmount[address(router)] = true;

        liquidityPair = IUniswapV2Factory(
                router.factory()
        ).createPair(
            address(this),
            router.WETH()
        );
        isExcludedMaxTransactionAmount[address(liquidityPair)] = true;
        LPTokenRecipient = LPTokenRecipient_;
        treasuryWallet = treasuryWallet_;

        uint256 totalSupply = 100_000_000 * 1e18;

        uint256 _sellLiquidityFee = 20;
        uint256 _sellTreasuryFee = 20;
        uint256 _buyLiquidityFee = 20;
        uint256 _buyTreasuryFee = 20;

        feeExcluded[address(this)] = true;
        isExcludedMaxTransactionAmount[address(this)] = true;

        isExcludedMaxTransactionAmount[address(0xdead)] = true;
        buyLiquidityFee = _buyLiquidityFee;
        sellTreasuryFee = _sellTreasuryFee;
        sellLiquidityFee = _sellLiquidityFee;
        feeExcluded[address(0xdead)] = true;
        buyTreasuryFee = _buyTreasuryFee;

        buyTotalFees = buyLiquidityFee + buyTreasuryFee;
        sellTotalFees = sellLiquidityFee + sellTreasuryFee;

        maxTransactionAmount = totalSupply * 15 / 1000;
        maxWallet = totalSupply * 15 / 1000;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(address(this), totalSupply);
    }

    receive() external payable {}

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount, address tokenRecipient) internal {
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

    function addInitialLiquidity() external payable onlyOwner {
        _addLiquidity(balanceOf(address(this)), msg.value, treasuryWallet);
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
                    from == liquidityPair &&
                    !isExcludedMaxTransactionAmount[to]
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
                    to == liquidityPair &&
                    !isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "!maxTransactionAmount."
                    );
                } else if (!isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "!maxWallet"
                    );
                }
            }
        }

        if (
            !swapping &&
            from != liquidityPair &&
            !feeExcluded[from] &&
            !feeExcluded[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (feeExcluded[from] || feeExcluded[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            if (to == liquidityPair && sellTotalFees > 0) {
                fees = amount * sellTotalFees / feeDenominator;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForTreasury += (fees * sellTreasuryFee) / sellTotalFees;
            }

            else if (from == liquidityPair && buyTotalFees > 0) {
                fees = amount * buyTotalFees / feeDenominator;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForTreasury += (fees * buyTreasuryFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
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

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function swapBack() internal {
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForTreasury;
        uint256 contractBalance = balanceOf(address(this));

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            // Reset to 0
            contractBalance = 0;
            totalTokensToSwap = 0;
            return;
        }

        uint256 lp = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance - lp;
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(amountToSwapForETH);
        uint256 ethBalance = (address(this).balance) - initialETHBalance;
        uint256 ethForTreasury = ethBalance * tokensForTreasury / totalTokensToSwap;
        uint256 ethForLiquidity = ethBalance - ethForTreasury;
        tokensForTreasury = 0;
        tokensForLiquidity = 0;

        if (lp > 0 && ethForLiquidity > 0) {
            _addLiquidity(lp, ethForLiquidity, LPTokenRecipient);
        }

        if (address(this).balance > 0) {
            bool success;
            (success, ) = address(treasuryWallet).call{value: address(this).balance}("");
        }
    }

}