/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

/*

    https://t.me/BongoCatPortal

    https://bongocat.fi/

    https://twitter.com/BongoCatCrypto

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
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

contract BongoCat is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "Bongo Cat";
    string private constant _symbol = "BONGO";
    uint8 private constant _decimals = 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public bots;

    uint256 private constant _tSupply = 1e12 * 10**(_decimals);
    uint256 private _tFeeTotal;
    uint256 private _taxFeeOnBuy = 3;
    uint256 private _taxFeeOnSell = 3;

    uint256 private _taxFee = _taxFeeOnSell;
    uint256 private _previoustaxFee = _taxFee;

    uint256 public _maxTxAmount = 2e9 * 10**(_decimals);
    uint256 public _maxWalletSize = 37e8 * 10**(_decimals);
    uint256 public _swapTokensAtAmount = 5e7 * 10**(_decimals);

    address payable private _marketingWalletAddress = payable(0xB5adB8cbEEA68D3E583926591cAf340C2Aa47457);

    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = true;


    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _balances[_msgSender()] = _tSupply;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_marketingWalletAddress] = true;

        emit Transfer(address(0), _msgSender(), _tSupply);
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
        return _tSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
                "BONGO: transfer amount exceeds allowance"
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
        require(owner != address(0), "BONGO: approve from the zero address");
        require(spender != address(0), "BONGO: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BONGO: transfer from the zero address");
        require(to != address(0), "BONGO: transfer to the zero address");
        require(amount > 0, "BONGO: transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to], "BONGO: your wallet is blacklisted");

            if (!tradingOpen) require(from == owner(), "BONGO: this account cannot send tokens until trading is enabled");

            require(amount <= _maxTxAmount, "BONGO: max transaction limit");

            if(to != uniswapV2Pair) require(balanceOf(to) + amount < _maxWalletSize, "BONGO: balance exceeds wallet size");

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

            if(contractTokenBalance >= _maxTxAmount) contractTokenBalance = _maxTxAmount;

            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) sendETHToFee(address(this).balance);
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if ((_isExcludedFromFees[from] || _isExcludedFromFees[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) takeFee = false;
        else {
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) _taxFee = _taxFeeOnBuy;
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) _taxFee = _taxFeeOnSell;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function sendETHToFee(uint256 amount) private {
        _marketingWalletAddress.transfer(amount);
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
        if (tTeam > 0) _takeTeam(tTeam);
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        _balances[address(this)] = _balances[address(this)].add(tTeam);
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
        uint256 tTeam = tAmount.mul(_taxFee).div(100);
        return (tAmount.sub(tTeam), tTeam);
    }

    function setTrading() public onlyOwner {
        require(!tradingOpen, "Trading is already opened.");
        tradingOpen = true;
    }

    function manualSwap() external {
        require(_msgSender() == _marketingWalletAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external {
        require(_msgSender() == _marketingWalletAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function blockBots(address[] memory bots_, bool isBlocked) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            require(bots_[i] != uniswapV2Pair, "Pair can't be blacklisted");
            bots[bots_[i]] = isBlocked;
        }
    }

    function setFees(uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner {
        require(taxFeeOnBuy.add(taxFeeOnSell) <= 20, "Must keep taxes below 20%");
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }

    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        require(maxTxAmount >= 1e9, "Must keep mx tx above 0.1% total supply");
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        require(maxWalletSize >= 1e10, "Must keep mx wallet above 1% total supply");
        _maxWalletSize = maxWalletSize;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) _isExcludedFromFees[accounts[i]] = excluded;
    }

}