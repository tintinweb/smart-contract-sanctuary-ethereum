/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function isOwner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);

        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }

        uint256 c = a * b;

        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);

        uint256 c = a / b;

        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin,
        address[] calldata path, address to, uint256 deadline) external;

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin,
        address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract Unnamed is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    string private constant contractName = "Unnamed";
    string private constant contractSymbol = "UNN";

    address payable private developmentAddress = payable(0x13D50312D9A5831443A1912263a4609ffD5fb231);
    address payable private marketingAddress = payable(0x13D50312D9A5831443A1912263a4609ffD5fb231);

    mapping(address => uint256) private tokensOwned;
    mapping(address => mapping(address => uint256)) private tokenAllowances;
    mapping(address => bool) private isExcludedFromFee;
    mapping(address => bool) public bots;
    mapping(address => uint256) public buyMap;

    uint8 private constant contractDecimals = 9;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant totalTokenSupply = 1000000 * 10 ** 9;
    uint256 private totalRemainder = (MAX - (MAX % totalTokenSupply));
    uint256 private totalTaxFee;
    uint256 private buyTaxFee = 4;
    uint256 private sellTaxFee = 4;
    uint256 private taxFee = sellTaxFee;
    uint256 private lastTaxFee = taxFee;

    bool private tradingOpen = true;
    bool private inSwap = false;
    bool private swapEnabled = true;

    uint256 public maxTransaction = 20000000 * 10 ** 9;
    uint256 public maxWallet = 20000000 * 10 ** 9;
    uint256 public swapAmount = 10000 * 10 ** 9;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    modifier lockTheSwap {
        inSwap = true; _; inSwap = false;
    }

    constructor() {
        tokensOwned[_msgSender()] = totalRemainder;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())

        .createPair(address(this), _uniswapV2Router.WETH());

        isExcludedFromFee[isOwner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[developmentAddress] = true;
        isExcludedFromFee[marketingAddress] = true;

        emit Transfer(address(0), _msgSender(), totalTokenSupply);
    }

    function name() public pure returns (string memory) {
        return contractName;
    }

    function symbol() public pure returns (string memory) {
        return contractSymbol;
    }

    function decimals() public pure returns (uint8) {
        return contractDecimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return totalTokenSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(tokensOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        transfer(_msgSender(), recipient, amount);

        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return tokenAllowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        approve(_msgSender(), spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        transfer(sender, recipient, amount);
        approve(sender, _msgSender(), tokenAllowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= totalRemainder, "Amount must be less than total reflections");

        uint256 currentRate = getRate();

        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (taxFee == 0) return;

        lastTaxFee = taxFee;
        taxFee = 0;
    }

    function restoreAllFee() private {
        taxFee = lastTaxFee;
    }

    function approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        tokenAllowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != isOwner() && to != isOwner()) {
            if (!tradingOpen) {
                require(from == isOwner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTransaction, "TOKEN: Max Transaction Limit");
            require(!bots[from] && !bots[to], "TOKEN: Your account is blacklisted!");

            if (to != uniswapV2Pair) {
                require(balanceOf(to) + amount < maxWallet, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            bool canSwap = contractTokenBalance >= swapAmount;

            if (contractTokenBalance >= maxTransaction) {
                contractTokenBalance = maxTransaction;
            }

            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !isExcludedFromFee[from] && !isExcludedFromFee[to]) {
                swapTokensForETH(contractTokenBalance);

                uint256 contractETHBalance = address(this).balance;

                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        if ((isExcludedFromFee[from] || isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                taxFee = buyTaxFee;
            }

            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                taxFee = sellTaxFee;
            }

        }

        tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function sendETHToFee(uint256 amount) private {
        marketingAddress.transfer(amount);
    }

    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }

    function manualswap() external {
        require(_msgSender() == developmentAddress || _msgSender() == marketingAddress);

        uint256 contractBalance = balanceOf(address(this));

        swapTokensForETH(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == developmentAddress || _msgSender() == marketingAddress);

        uint256 contractETHBalance = address(this).balance;

        sendETHToFee(contractETHBalance);
    }

    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();

        transferStandard(sender, recipient, amount);

        if (!takeFee) restoreAllFee();
    }

    function transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount,  uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = getValues(tAmount);

        tokensOwned[sender] = tokensOwned[sender].sub(rAmount);
        tokensOwned[recipient] = tokensOwned[recipient].add(rTransferAmount);

        takeTeamFee(tTeam);
        reflectionFee(tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function takeTeamFee(uint256 tTeam) private {
        uint256 currentRate = getRate();
        uint256 rTeam = tTeam.mul(currentRate);

        tokensOwned[address(this)] = tokensOwned[address(this)].add(rTeam);
    }

    function reflectionFee(uint256 tFee) private {
        totalTaxFee = totalTaxFee.add(tFee);
    }

    receive() external payable {}

    function getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = getTaxValues(tAmount, taxFee);

        uint256 currentRate = getRate();

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = getReflectionValues(tAmount, tFee, currentRate);

        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function getTaxValues(uint256 tAmount, uint256 tax) private pure returns (uint256, uint256) {
        uint256 tTeam = tAmount.mul(tax).div(100);
        uint256 tTransferAmount = tAmount.sub(tTeam);

        return (tTransferAmount, tTeam);
    }

    function getReflectionValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);

        return (rAmount, rTransferAmount, rFee);
    }

    function getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();

        return rSupply.div(tSupply);
    }

    function getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = totalRemainder;
        uint256 tSupply = totalTokenSupply;

        if (rSupply < totalRemainder.div(totalTokenSupply)) return (totalRemainder, totalTokenSupply);

        return (rSupply, tSupply);
    }

    function setFee(uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner {
        buyTaxFee = taxFeeOnBuy;
        sellTaxFee = taxFeeOnSell;
    }

    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        swapAmount = swapTokensAtAmount;
    }

    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    //Set maximum transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        maxTransaction = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        maxWallet = maxWalletSize;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFee[accounts[i]] = excluded;
        }
    }
}