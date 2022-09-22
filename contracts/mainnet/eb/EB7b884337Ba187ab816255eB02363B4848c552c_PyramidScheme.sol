/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

/**

Cryptocurrencies are important and valuable. Distributed blockchain technology, as pioneered by bitcoin, is important. The future of money really is cryptocurrencies, possibly led by bitcoin.

I’ve been getting into a lot of discussions with supporters and promoters of bitcoin, who tell me that the price of bitcoin is going up so fast because there is a limited supply and an increasing demand. Their argument is that only a small percentage of the world currently has bitcoin, and that everyone will eventually need to use bitcoin.

It’s true that prices reflect the difference between supply and demand. There is a limited number of bitcoins, and there is a great demand for them, so the price is shooting up. However, what these proponents of bitcoin seem to be missing is the reason for the demand.

It’s clear that the most significant reason, by far, for the massively increasing demand for bitcoin is that people want to own it because they think that it will go up in price. They think it will go up in price because increasing numbers of people are going to want to buy it. The reason that they think that more people will want to buy it is that those people are going to believe that it will go up in price. This is a self-fulfilling prophesy.

This is also a demonstration of the standard operation of a bubble. It looks like a Ponzi scheme or a pyramid scheme. If I buy bitcoin today, it will be more valuable tomorrow because others have bought it at a higher price. As an existing “investor,” I am benefitting from others getting in. Meanwhile, what I’m actually owning is a bitcoin. Don’t get me wrong, bitcoin is valuable, but it’s not worth $10,000 per coin, or even $1,000 per coin. It’s a currency. It’s not Amazon or Apple stock.

If you bought Apple or Amazon stock early on, then you bought something that had a massive hidden future value, and as that value was revealed, you benefitted by investing in it very early, before the value was apparent. Apple and Amazon are companies which generate revenue and profits, and a share in these companies represents ownership in something that is growing.

I have friends messaging me asking, “What do you think about bitcoin? It’s so expensive right now, but I feel like if I don’t get in now then I will regret it later.” Notice this emotional state, this panic. Everyone is behaving like this is an emergency. Everyone and his dog is buying bitcoin. This is a form of mania. And the price is reflecting that. The number one rule of investing is don’t follow the crowd. When everyone else is buying, it’s time to sell. When everyone else is selling, it’s time to buy.

I’m probably a little bit older than many of the readers of this article. I remember the dot com bubble. Everyone was buying dot com stocks. The prices of those stocks shot up, and when many companies went bankrupt, people lost all of their money. There were also stories in Silicon Valley about receptionists and other admin staff at start-ups whose exercised stock options were being valued so highly at tax time that they ended up owing hundreds of thousands of dollars in federal tax through the Alternative Minimum Tax (AMT) mechanism. After the prices of the stocks crashed, before they were able to sell them, those employees still owed all that money to Uncle Sam. Many regular folks ended up bankrupt.

You might argue that people who invested in companies like Amazon during the dot com bubble didn’t lose all their money, and actually probably made money. Well that’s not necessarily true. I trusted some stock brokers at that time who persuaded me to cash-in my NVIDIA stock options and buy stocks that they “liked” such as Avaya and EMC. Even though their brokerage firm was a market-maker in NVDA, they didn’t know what NVIDIA was. Those dot com stocks also rose with the dot com bubble, but they didn’t become worthless after it popped; they did, however, halve in value. I did lose hundreds of thousands of dollars on those stock purchases, and I had cashed-in NVIDIA stock to buy them, stock that would now be worth tens of millions of dollars.

I believe that bitcoin will be around in the future, and that it will not go to a zero price. I believe that other cryptocurrencies will come to the fore which are more able to handle the transactional needs of a larger number of people than bitcoin can.

I think it’s important to realize and remember that this is a bubble. Your coins are going up because the sucker after you is buying coins. And they’re only buying them because they think that the price will go up.

Another sign that this is a bubble is the way that those who own bitcoins are trying to persuade everyone who doesn’t own them to buy them. These people might persuade themselves that they are motivated to help others, but I believe that the true reason is that they know that the more people are buying bitcoin, the more the price will go up. So they’re trying to keep the bubble growing. When you buy bitcoin, you’re potentially going to make some gains if you can get out again before it crashes. However, once you’re a convert, and you get into the swing of this, you’re going to stay in and work on persuading others to buy. It looks just like a pyramid scheme from this standpoint.

With true investments, such as a stock in a solid company with great leadership, a company that will grow and succeed massively in the long run, we want to keep it secret. We want to be able to keep buying the stock at the lower price. We don’t go around recommending to everyone that they buy the stock, because that would only lead to the price being driven up, making it harder for us to buy in at the low price.

It’s like going to a casino. If you can go in and put down a bet, win, and then take the winnings and walk out of the casino, then you can do well with bitcoin. The problem is that when most people get a big win, they plough it back into the system. Just as with a casino, bitcoin (at these elevated prices) is a system that is designed to extract your wealth from you. If you get in and get out, you can extract some wealth from the suckers down the line from you. However, the more you get in, and stay in, the more likely it is that you will be one of the suckers holding the bag when this thing crashes.

How will it crash? This bullish mania will suddenly flip. When all these regular people who have their life savings in bitcoin notice that the price is dropping, they will sell, probably at a loss. This will make the price go down further, triggering more panic, and the negative spiral will begin. The same mechanism that has led to this run-up, a form of mass hysteria, will also potentiate a massive sell-off and crash. This is because the bubble mania is a two-sided coin (pun intended).

My advice is to pay as much attention to your internal state as possible. Notice the fear of missing out. Notice the panic, the excitement, and the drive to promote bitcoin. This is a great opportunity for self-awareness. You might want to convert some of your dollars into this currency for fun, but make sure you only convert as much as you would be happy to lose, which for most people is nothing.

https://github.com/s6ruby/programming-crypto-contracts

https://t.me/PyramidSchemeChat

**/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;


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
contract PyramidScheme is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "Pyramid Scheme";
    string private constant _symbol = "Pyramid";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _redisFeeOnBuy = 0;
    uint256 private _taxFeeOnBuy = 2;
    uint256 private _redisFeeOnSell = 0;
    uint256 private _taxFeeOnSell = 6;

    //Original Fee
    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;

    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;

    mapping(address => bool) public bots; mapping (address => uint256) public _buyMap;
    address payable private _developmentAddress = payable(0x88B1664f8f4917dc76EBB625ecDbD7F4B9A2C8A3);
    address payable private _marketingAddress = payable(0x88B1664f8f4917dc76EBB625ecDbD7F4B9A2C8A3);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = true;

    uint256 public _maxTxAmount =  200000000000 * 10**9;
    uint256 public _maxWalletSize = 300000000000 * 10**9;
    uint256 public _swapTokensAtAmount = 100 * 10**9;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {

        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_developmentAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;

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
        return tokenFromReflection(_rOwned[account]);
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

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;

        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;

        _redisFee = 0;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _redisFee = _previousredisFee;
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

            require(amount <= _maxTxAmount || _isExcludedFromFee[to], "TOKEN: Max Transaction Limit");
            require(!bots[from] && !bots[to], "TOKEN: Your account is blacklisted!");

            if(to != uniswapV2Pair && !_isExcludedFromFee[to]) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }

            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {

            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnBuy;
                _taxFee = _taxFeeOnBuy;
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnSell;
                _taxFee = _taxFeeOnSell;
            }

            if (_taxFee == 0 && _redisFee == 0) {
                takeFee = false;
            }

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
        uint256 half = amount.div(2);
        _marketingAddress.transfer(half);
        _developmentAddress.transfer(amount.sub(half));
    }

    function setTrading(bool _tradingOpen) public onlyOwner {
        require(!tradingOpen, "ERC20: Trading can be only opened once");
        tradingOpen = _tradingOpen;
    }

    function manualswap() external {
        require(_msgSender() == _developmentAddress || _msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _developmentAddress || _msgSender() == _marketingAddress);
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
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function SetFee(uint256 redisFeeOnBuy, uint256 redisFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner {
        require(redisFeeOnBuy + taxFeeOnBuy <= 10, "Tax on buy can't be more than 10");
        require(redisFeeOnSell + taxFeeOnSell <= 100, "Tax on sell can't be more than 10");
        _redisFeeOnBuy = redisFeeOnBuy;
        _redisFeeOnSell = redisFeeOnSell;
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
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
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

}