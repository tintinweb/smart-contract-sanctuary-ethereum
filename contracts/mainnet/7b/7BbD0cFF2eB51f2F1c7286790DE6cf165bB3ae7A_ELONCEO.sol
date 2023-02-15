/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// https://t.me/elonceoportal

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
    )
    external
    payable
    returns (
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

contract ELONCEO is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);

    bool private swapping;

    uint256 public maxTnxAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;

    address private marketingWallet = _msgSender();
    struct Taxes {
        uint256 marketing;
        uint256 liquidity;
        uint256 burn;
        uint256 total;
    }
    Taxes public buyTax;
    Taxes public sellTax;

    uint256 private tokensForMarketing;
    uint256 private tokensForLiquidity;
    uint256 private tokensForBurn;

    mapping(address => bool) private isExcludedFromFees;
    mapping(address => bool) private isExcludedMaxTnxAmount;

    constructor() ERC20("ELON CEO", "ELONCEO", 18) {
        address routerAddress;
        // BSC Mainnet Router
        if (block.chainid == 56) {
            routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        }
        // Polygon Ropsten Router
        else if (block.chainid == 137) {
            routerAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; 
        }
        // Arbitrum One Router
        else if (block.chainid == 42161) {
            routerAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; 
        }
        // ETH Mainnet & Testnet
        else if (block.chainid == 1 || block.chainid == 5) {
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else {
            revert();
        }
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        isExcludedMaxTnxAmount[address(_uniswapV2Router)] = true;
        isExcludedMaxTnxAmount[address(uniswapV2Pair)] = true;
        
        uint256 totalSupply = 10000000 * (10**decimals());
        maxTnxAmount = totalSupply.mul(2).div(100);
        maxWallet = totalSupply.mul(2).div(100);
        swapTokensAtAmount = totalSupply.mul(5).div(10000);

        buyTax = Taxes(7, 0, 0, 7);
        sellTax = Taxes(32, 0, 0, 32);

        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[DEAD] = true;

        isExcludedMaxTnxAmount[owner()] = true;
        isExcludedMaxTnxAmount[address(this)] = true;
        isExcludedMaxTnxAmount[DEAD] = true;

        _mint(_msgSender(), totalSupply);
    }

    receive() external payable {}

    function removeLimits() external onlyOwner {
        require(limitsInEffect, "The limits in effect has been removed.");
        limitsInEffect = false;
    }

    function updateSwapTokensAtAmount(uint256 _swapTokensAtAmount) external onlyOwner {
        _swapTokensAtAmount = _swapTokensAtAmount.mul(10**decimals());
        require(_swapTokensAtAmount >= totalSupply().mul(1).div(100000), "Swap amount cannot be lower than 0.001% total supply.");
        require(_swapTokensAtAmount <= totalSupply().mul(5).div(1000), "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = _swapTokensAtAmount;
    }

    function updateMaxWalletAndTxnAmount(uint256 _maxTnxAmount, uint256 _maxWallet) external onlyOwner {
        _maxTnxAmount = _maxTnxAmount.mul(10**decimals());
        _maxWallet = _maxWallet.mul(10**decimals());
        uint256 limit = totalSupply().mul(5).div(1000);
        require(_maxTnxAmount >= limit, "Cannot set maxTxn lower than 0.5%");
        require(_maxWallet >= limit, "Cannot set maxWallet lower than 0.5%");
        maxTnxAmount = _maxTnxAmount;
        maxWallet = _maxWallet;
    }

    function updateBuyTaxes(uint256 marketing, uint256 liquidity, uint256 burn) external onlyOwner {
        buyTax = Taxes(marketing, liquidity, burn, marketing + liquidity + burn);
        require(buyTax.total <= 5, "Must keep fees at 5% or less.");
    }

    function updateSellTaxes(uint256 marketing, uint256 liquidity, uint256 burn) external onlyOwner {
        sellTax = Taxes(marketing, liquidity, burn, marketing + liquidity + burn);
        require(sellTax.total <= 7, "Must keep fees at 7% or less.");
    }

    function updateMarketingWallet(address _marketingWallet) external onlyOwner {
        require(_marketingWallet != ZERO, "Marketing wallet cannot be zero address");
        marketingWallet = _marketingWallet;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != ZERO, "ERC20: transfer from the zero address");
        require(to != ZERO, "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (from != owner() && to != owner() && to != ZERO && to != DEAD && !swapping && limitsInEffect) {
                if (uniswapV2Pair == from && !isExcludedMaxTnxAmount[to]) {
                    require(amount <= maxTnxAmount, "Buy transfer amount exceeds the max transaction amount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
                else if (uniswapV2Pair == to && !isExcludedMaxTnxAmount[from]) {
                    require(amount <= maxTnxAmount, "Sell transfer amount exceeds the max transaction amount.");
                }
                else if (!isExcludedMaxTnxAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }

        if (
            balanceOf(address(this)) >= swapTokensAtAmount &&
            !swapping &&
            uniswapV2Pair == to &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            if (uniswapV2Pair == to && sellTax.total > 0) {
                fees = amount.mul(sellTax.total).div(100);
                tokensForLiquidity += (fees * sellTax.liquidity) / sellTax.total;
                tokensForMarketing += (fees * sellTax.marketing) / sellTax.total;
                tokensForBurn += (fees * sellTax.burn) / sellTax.total;
            }
            else if (uniswapV2Pair == from && buyTax.total > 0) {
                fees = amount.mul(buyTax.total).div(100);
                tokensForLiquidity += (fees * buyTax.liquidity) / buyTax.total;
                tokensForMarketing += (fees * buyTax.marketing) / buyTax.total;
                tokensForBurn += (fees * buyTax.burn) / buyTax.total;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }

        super._transfer(from, to, amount);
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            DEAD,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForBurn;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing);

        uint256 ethForLiquidity = ethBalance - ethForMarketing;

        if(tokensForBurn > 0) {
            _burn(address(this), tokensForBurn);
        }

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForBurn = 0;

        (success, ) = address(marketingWallet).call{value: address(this).balance}("");
    }

    function withdrawStuckedBalance(uint256 _mount) external onlyOwner {
        require(address(this).balance >= _mount, "Insufficient balance");
        payable(msg.sender).transfer(_mount);
    }

    function withdrawStuckedTokens(address _tokenAddress, address _to, uint256 _amount) external onlyOwner returns (bool) {
        require(_tokenAddress != address(this), "Owner can't claim contract's balance of its own tokens");
        return ERC20(_tokenAddress).transfer(_to, _amount);
    }
}