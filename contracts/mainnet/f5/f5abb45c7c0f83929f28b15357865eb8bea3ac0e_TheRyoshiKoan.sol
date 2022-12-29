/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*

The Zen master sat quietly in the garden, tending to the plants with gentle hands. A student approached and asked, "Master, what is the meaning of patience?"

The master replied, "It is like the roots of a tree, deep and unseen, but essential for growth and stability."

The student asked, "And what is the meaning of wealth?"

The master replied, "It is like the branches of a tree, reaching towards the sky and bearing fruit. But it is not the branches alone that bring abundance, it is the harmony between the roots and the branches, the balance between stillness and action."

The student nodded and sat in silence, contemplating the words of the Zen master.

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

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface IERC20Metadata is IERC20 {

    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

}

contract ERC20 is IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;
    string private _symbol;

    uint256 private _totalSupply;

    string private _name;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
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

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
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

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
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

contract TheRyoshiKoan is ERC20, Ownable {

    uint256 public tokensForLiquidity;
    address public devWallet;
    uint256 public sellLiquidityFee;

    uint256 public buyTotalFees;
    uint256 public maxTransactionAmount;
    uint256 public buyLiquidityFee;
    mapping(address => bool) public isExcludedMaxTxn;
    uint256 public tokensForDev;
    uint256 public sellDevFee;


    uint256 public buyDevFee;
    uint256 public sellTotalFees;
    IUniswapV2Router02 public immutable router;
    uint256 public maxWallet;

    address public LpReceiver;
    address public immutable ethPair;
    bool private swapping;

    uint256 public feeDenominator = 1000;
    bool public limitsInEffect = true;
    mapping(address => bool) private noFee;

    constructor(address router_, address devWallet_, address LpReceiver_) ERC20("The Ryoshi Koan", "TRK") {

        router = IUniswapV2Router02(router_);

        LpReceiver = LpReceiver_;
        ethPair = IUniswapV2Factory(
                router.factory()
        ).createPair(
            address(this),
            router.WETH()
        );
        isExcludedMaxTxn[address(router)] = true;

        isExcludedMaxTxn[address(ethPair)] = true;
        devWallet = devWallet_;

        uint256 totalSupply = 100_000_000 * 1e18;

        uint256 _sellLiquidityFee = 10;
        uint256 _sellDevFee = 30;
        uint256 _buyLiquidityFee = 10;
        uint256 _buyDevFee = 30;

        sellLiquidityFee = _sellLiquidityFee;
        isExcludedMaxTxn[address(this)] = true;
        noFee[address(this)] = true;
        buyLiquidityFee = _buyLiquidityFee;
        isExcludedMaxTxn[address(0xdead)] = true;
        sellDevFee = _sellDevFee;
        buyDevFee = _buyDevFee;

        noFee[address(0xdead)] = true;

        buyTotalFees = buyLiquidityFee + buyDevFee;
        sellTotalFees = sellLiquidityFee + sellDevFee;

        maxTransactionAmount = totalSupply * 20 / 1000;
        maxWallet = totalSupply * 20 / 1000;


        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(address(this), totalSupply);
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

    function swapBack() internal {
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForDev;
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
        uint256 ethForDev = ethBalance * tokensForDev / totalTokensToSwap;
        uint256 ethForLiquidity = ethBalance - ethForDev;
        tokensForDev = 0;
        tokensForLiquidity = 0;

        if (liquidity > 0 && ethForLiquidity > 0) {
            _addAMMLiquidity(liquidity, ethForLiquidity, LpReceiver);
        }

        if (address(this).balance > 0) {
            bool success;
            (success, ) = address(devWallet).call{value: address(this).balance}("");
        }
    }

    receive() external payable {}

    function addInitialLiquidityAndStartTrading() external payable onlyOwner {
        _addAMMLiquidity(balanceOf(address(this)), msg.value, devWallet);
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
                    from == ethPair &&
                    !isExcludedMaxTxn[to]
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
                    to == ethPair &&
                    !isExcludedMaxTxn[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "!maxTransactionAmount."
                    );
                } else if (!isExcludedMaxTxn[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "!maxWallet"
                    );
                }
            }
        }

        if (
            !swapping &&
            from != ethPair &&
            !noFee[from] &&
            !noFee[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (noFee[from] || noFee[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            if (to == ethPair && sellTotalFees > 0) {
                fees = amount * sellTotalFees / feeDenominator;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForDev += (fees * sellDevFee) / sellTotalFees;
            }

            else if (from == ethPair && buyTotalFees > 0) {
                fees = amount * buyTotalFees / feeDenominator;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForDev += (fees * buyDevFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

}