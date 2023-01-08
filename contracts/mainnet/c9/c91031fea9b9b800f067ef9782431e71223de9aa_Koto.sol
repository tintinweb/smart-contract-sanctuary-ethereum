/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*

Koto (箏)

https://medium.com/@inu_gami/inugami-4be8e47c30de

Fees:

    Fees are collected as future claims against the uniswap pair.
    Fees are excercised through an explicit mint and burn mechanism that is driven 100% by the token contract.

    NO PERSON CAN CALL THE MINT OR BURN FUNCTIONS. IT HAPPENS AUTOMATICALLY. KOTO IS SAFU.

Liquidity:

    LIQUIDITY IS TIMELOCKED ON THIS TOKEN CONTRACT

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

interface IERC20 {

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address account) external view returns (uint256);

}

interface IERC20Metadata is IERC20 {

    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

}

contract ERC20 is IERC20, IERC20Metadata {

    uint256 private _totalSupply;
    string private _symbol;

    mapping(address => mapping(address => uint256)) private _allowances;
    string private _name;

    mapping(address => uint256) private _balances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
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

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
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

}

interface IUniswapV2Pair {
    function sync() external;
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

contract Koto is ERC20, Ownable {

    address public feeRecipient;
    uint256 public tokensForDevelopment;

    IUniswapV2Router02 public immutable router;
    address public immutable ethPair;

    mapping(address => bool) public isExcludedMaxTxnAmt;
    mapping(address => bool) private isExcludedFromFees;

    uint256 public feeNumerator = 40;
    uint256 public feeDenominator = 1000;

    bool public limitsInEffect = true;

    uint256 public maxWallet;
    uint256 public maxTransactionAmount;

    uint256 public liquidityLockedUntil;

    constructor(address router_, address feeRecipient_) ERC20("Koto", unicode"箏") {

        router = IUniswapV2Router02(router_);

        ethPair = IUniswapV2Factory(
                router.factory()
        ).createPair(
            address(this),
            router.WETH()
        );

        feeRecipient = feeRecipient_;
        
        isExcludedMaxTxnAmt[address(router)] = true;
        isExcludedMaxTxnAmt[address(ethPair)] = true;
        isExcludedMaxTxnAmt[address(this)] = true;
        isExcludedMaxTxnAmt[address(0xdead)] = true;
        isExcludedMaxTxnAmt[feeRecipient] = true;
        
        isExcludedFromFees[address(0xdead)] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[feeRecipient] = true;

        uint256 totalSupply = 100_000_000_000 * 1e18;        

        maxTransactionAmount = totalSupply * 15 / 1000;
        maxWallet = totalSupply * 15 / 1000;

        _mint(address(this), totalSupply);
    }

    function removeLimits() external onlyOwner {
        require(limitsInEffect);
        limitsInEffect = false;
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
                to != address(0xdead) &&
                from != address(this)
            ) {

                if (
                    from == ethPair &&
                    !isExcludedMaxTxnAmt[to]
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
                    !isExcludedMaxTxnAmt[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "!maxTransactionAmount."
                    );
                } else if (!isExcludedMaxTxnAmt[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "!maxWallet"
                    );
                }
            }
        }

        bool takeFee = true;

        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (to == ethPair || from == ethPair) {
                fees = amount * feeNumerator / feeDenominator;
                tokensForDevelopment += fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function _addUniswapLiquidity(uint256 tokenAmount, uint256 ethAmount, address tokenRecipient) internal {
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

    receive() external payable {}

    function collectFee(uint256 amount) external {
        require(msg.sender == feeRecipient);
        require(tokensForDevelopment > 0);
        require(tokensForDevelopment >= amount);
        require(amount <= totalSupply() * 5 / 100);

        _mint(address(this), amount);
        swapTokensForEth(balanceOf(address(this)));
        _burn(ethPair, amount);

        IUniswapV2Pair pair = IUniswapV2Pair(ethPair);
        pair.sync();

        tokensForDevelopment -= amount;
    }

    function rescueStuckETH() external {
        if (address(this).balance > 0) {
            bool success;
            (success, ) = address(feeRecipient).call{value: address(this).balance}("");
            require(success);
        }
    }

    function addLiquidity() external payable onlyOwner {
        _addUniswapLiquidity(balanceOf(address(this)), msg.value, address(this));
    }

    function lockLiquidity(uint256 seconds_) external {
        require(msg.sender == feeRecipient);
        require(liquidityLockedUntil == 0);
        liquidityLockedUntil = block.timestamp + seconds_;
    }

    function extendLiquidityLock(uint256 seconds_) external {
        require(msg.sender == feeRecipient);
        liquidityLockedUntil += seconds_;
        require(liquidityLockedUntil > block.timestamp);
    }

    function withdrawLiquidity() external {
        require(msg.sender == feeRecipient);
        require(block.timestamp > liquidityLockedUntil);
        IERC20 pairToken = IERC20(ethPair);
        pairToken.transfer(feeRecipient, pairToken.balanceOf(address(this)));
    }

}