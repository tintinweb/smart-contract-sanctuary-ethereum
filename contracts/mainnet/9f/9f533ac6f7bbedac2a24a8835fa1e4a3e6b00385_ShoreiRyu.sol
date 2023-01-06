/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*

- Shorei Ryu
- https://shorei-ryu.webflow.io
- https://medium.com/@shorei-ryu/sh%C5%8Drei-ry%C5%AB-shorei-e018a40f6548

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

contract ShoreiRyu is ERC20, Ownable {

    address public LPTokenReceiver;

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    IUniswapV2Router02 public immutable router;
    address public immutable uniswapPair;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;

    mapping(address => bool) private ifNoFee;
    mapping(address => bool) public isExcludedMaxTransactionAmount;

    uint256 public feeDenominator = 1000;
    
    bool private swapping;
    bool public limitsInEffect = true;

    constructor(address router_, address LPTokenReceiver_) ERC20("Shorei Ryu", "SRYU") {

        LPTokenReceiver = LPTokenReceiver_;

        router = IUniswapV2Router02(router_);
        uniswapPair = IUniswapV2Factory(
                router.factory()
        ).createPair(
            address(this),
            router.WETH()
        );

        isExcludedMaxTransactionAmount[address(uniswapPair)] = true;
        isExcludedMaxTransactionAmount[address(router)] = true;        
        isExcludedMaxTransactionAmount[address(this)] = true;
        isExcludedMaxTransactionAmount[address(0xdead)] = true;
        isExcludedMaxTransactionAmount[msg.sender] = true;

        uint256 totalSupply = 100_000_000 * 1e18;

        buyTotalFees = 50;
        sellTotalFees = 99;

        ifNoFee[address(0xdead)] = true;
        ifNoFee[address(this)] = true;
        ifNoFee[msg.sender] = true;

        maxTransactionAmount = totalSupply * 20 / 1000;
        maxWallet = totalSupply * 10 / 1000;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function setFees(uint256 buyFee, uint256 sellFee) external onlyOwner {
        // All fees go towards liquidity
        buyTotalFees = buyFee;
        sellTotalFees = sellFee;
    }

    function setLimits(uint256 maxTransactionAmount_, uint256 maxWallet_) external onlyOwner {
        maxTransactionAmount = maxTransactionAmount_;
        maxWallet = maxWallet_;
    }

    function removeLimits() external onlyOwner {
        require(limitsInEffect);
        limitsInEffect = false;
    }

    function rescueStuckETH() external {
        if (address(this).balance > 0) {
            bool success;
            (success, ) = address(LPTokenReceiver).call{value: address(this).balance}("");
            require(success);
        }
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
                    from == uniswapPair &&
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
                    to == uniswapPair &&
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
            from != uniswapPair &&
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
            if (to == uniswapPair && sellTotalFees > 0) {
                fees = amount * sellTotalFees / feeDenominator;
            }

            else if (from == uniswapPair && buyTotalFees > 0) {
                fees = amount * buyTotalFees / feeDenominator;
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

    function swapBack() internal {
        uint256 contractBalance = balanceOf(address(this));

        if (contractBalance == 0) {
            return;
        }

        uint256 liquidity = contractBalance / 2;
        uint256 amountToSwapForETH = contractBalance - liquidity;
        swapTokensForEth(amountToSwapForETH);
        uint256 ethForLiquidity = address(this).balance;

        if (liquidity > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidity, ethForLiquidity);
        }

    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            LPTokenReceiver,
            block.timestamp
        );
    }

}