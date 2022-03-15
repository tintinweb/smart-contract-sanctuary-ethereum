/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


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

    function owner() public view returns (address) {
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
}

contract unitedDegens is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "United Degens";//
    string private constant _symbol = "UNITED";//
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant _tTotal = 200000000 * 10 ** 9;
    uint256 public launchBlock;


    //Liquidity Fee Buy
    uint256 private _liquidityFeeBuy = 2;

    //Liquidity Fee Buy
    uint256 private _devFeeBuy = 1;

    //Liquidity Fee Marketing
    uint256 private _marketingFeeBuy = 8;

    //Liquidity Fee Sell
    uint256 private _liquidityFeeSell = 5;

    //Liquidity Fee Buy
    uint256 private _devFeeSell = 1;

    //Liquidity Fee Marketing
    uint256 private _marketingFeeSell = 9;


    //Buy Fee
    uint256 private _taxFeeOnBuy = _liquidityFeeBuy + _devFeeBuy + _marketingFeeBuy;//

    //Sell Fee
    uint256 private _taxFeeOnSell = 99;//

    //Original Fee
    uint256 private _taxFee = _taxFeeOnSell;

    uint256 private _previoustaxFee = _taxFee;

    mapping(address => bool) public bots;

    address payable private _developmentAddress = payable(0xFFE15d77C78FBD20c4571064e161A22c4114aab3);//
    address payable private _marketingAddress = payable(0x6173868A5e412129F5EC7f6f1116Abf779ABa47f);//

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingOpen;
    bool private inSwap = false;
    bool private inSend = false;
    bool private swapEnabled = true;

    uint256 public _maxTxAmount = 1000000 * 10 ** 9; //
    uint256 public _maxWalletSize = 2000000 * 10 ** 9; //
    uint256 public _swapTokensAtAmount = 10000 * 10 ** 9; //

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier lockTheSend {
        inSend = true;
        _;
        inSend = false;
    }
    constructor(address router) {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_developmentAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;

        bots[address(0x66f049111958809841Bbe4b81c034Da2D953AA0c)] = true;
        bots[address(0x000000005736775Feb0C8568e7DEe77222a26880)] = true;
        bots[address(0x34822A742BDE3beF13acabF14244869841f06A73)] = true;
        bots[address(0x69611A66d0CF67e5Ddd1957e6499b5C5A3E44845)] = true;
        bots[address(0x69611A66d0CF67e5Ddd1957e6499b5C5A3E44845)] = true;
        bots[address(0x8484eFcBDa76955463aa12e1d504D7C6C89321F8)] = true;
        bots[address(0xe5265ce4D0a3B191431e1bac056d72b2b9F0Fe44)] = true;
        bots[address(0x33F9Da98C57674B5FC5AE7349E3C732Cf2E6Ce5C)] = true;
        bots[address(0xc59a8E2d2c476BA9122aa4eC19B4c5E2BBAbbC28)] = true;
        bots[address(0x21053Ff2D9Fc37D4DB8687d48bD0b57581c1333D)] = true;
        bots[address(0x4dd6A0D3191A41522B84BC6b65d17f6f5e6a4192)] = true;

        _tOwned[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }


    function removeAllFee() private {
        if (_taxFee == 0) return;

        _previoustaxFee = _taxFee;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previoustaxFee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {

            //Trade start check
            if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            require(!bots[from] && !bots[to], "TOKEN: Your account is blacklisted!");

            if (block.number <= launchBlock && from == uniswapV2Pair && to != address(uniswapV2Router) && to != address(this)) {
                bots[to] = true;
            }

            if (to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance * 10 ** 9 >= _swapTokensAtAmount;

            if (contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }

            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapAndLiquidate(contractTokenBalance);
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {

            //Set Fee for Buys
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _taxFee = _taxFeeOnBuy;
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _taxFee = _taxFeeOnSell;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquidate(uint256 contractTokenBalance) private lockTheSwap {
        uint256 devTokens = contractTokenBalance.mul(_devFeeBuy + _devFeeSell).div(_taxFeeOnBuy + _taxFeeOnSell);
        uint256 marketingTokens = contractTokenBalance.mul(_marketingFeeBuy + _marketingFeeSell).div(_taxFeeOnBuy + _taxFeeOnSell);

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(devTokens + marketingTokens);
        uint256 diffBalance = address(this).balance.sub(initialBalance);
        uint256 devShare = diffBalance.mul(_devFeeBuy + _devFeeSell).div(_devFeeBuy + _devFeeSell + _marketingFeeBuy + _marketingFeeSell);
        uint256 marketingShare = diffBalance.sub(devShare);
        _developmentAddress.transfer(devShare);
        _marketingAddress.transfer(marketingShare);

        uint256 tokensForLiquidity = contractTokenBalance.sub(devTokens).sub(marketingTokens);
        uint256 half = tokensForLiquidity.div(2);
        uint256 otherHalf = tokensForLiquidity.sub(half);

        initialBalance = address(this).balance;
        swapTokensForEth(half);
        diffBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, diffBalance);
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
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _developmentAddress.transfer(amount.div(2));
        _marketingAddress.transfer(amount.div(2));
    }

    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
        launchBlock = block.number;
    }

    function manualswap() external {
        require(_msgSender() == _developmentAddress || _msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapAndLiquidate(contractBalance);
    }

    function manualsend() external lockTheSend {
        require(_msgSender() == _developmentAddress || _msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;

        uint256 devShare = contractETHBalance.mul(_devFeeBuy + _devFeeSell).div(_devFeeBuy + _devFeeSell + _marketingFeeBuy + _marketingFeeSell);
        uint256 marketingShare = contractETHBalance.sub(devShare);
        _developmentAddress.transfer(devShare);
        _marketingAddress.transfer(marketingShare);
    }

    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
        uint256 tTransferAmount,
        uint256 tTeam
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tTransferAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _tOwned[address(this)] = _tOwned[address(this)].add(tTeam);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    receive() external payable {}

    function _getValues(uint256 tAmount)
    private
    view
    returns (
        uint256,
        uint256
    )
    {

        (uint256 tTransferAmount, uint256 tTeam) =
        _getTValues(tAmount, _taxFee);

        return (tTransferAmount, tTeam);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 taxFee
    )
    private
    pure
    returns (
        uint256,
        uint256
    )
    {
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tTeam);

        return (tTransferAmount, tTeam);
    }

    function setFee(uint256 liquidityFeeBuy, uint256 marketingFeeBuy, uint256 liquidityFeeSell, uint256 marketingFeeSell) public onlyOwner {
        _liquidityFeeBuy = liquidityFeeBuy;
        _marketingFeeBuy = marketingFeeBuy;
        _liquidityFeeSell = liquidityFeeSell;
        _marketingFeeSell = marketingFeeSell;

        _taxFeeOnSell = _liquidityFeeSell + _devFeeSell + _marketingFeeSell;
    }

    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }

    //Set minimum tokens required to swap.
    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }


    //Set maximum transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

    function isExcludedFromFee(address account) public onlyOwner view returns (bool) {
        return _isExcludedFromFee[account];
    }
}