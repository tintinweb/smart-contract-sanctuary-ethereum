/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

/*
Each time they jeet, your bag grows.

https://t.me/catchajeet

https://www.catchajeet.vip/

https://twitter.com/CatchAJeet
*/

// pragma solidity ^0.8.9; 

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

contract CATCH is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "Catch a Jeet";
    string private constant _symbol = "CATCH";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000000 * 10**9;
    uint256 private _tFeeTotal;
    uint256 private _taxFeeOnBuy = 15;
    uint256 private _taxFeeOnSell = 28;

    // last buyer of minimum amount
    address public latestBuyer = address(0);

    //Original Fee
    uint256 private _taxFee = _taxFeeOnSell;

    uint256 private _previoustaxFee = _taxFee;

    mapping (address => uint256) public _buyMap;

    address payable private _marketingAddress = payable(0xe4B89B25879F1174784F640921DFb05E191DfA6E);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address private constant swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bool private tradingOpen = true;
    bool private startGame = false;
    bool private inSwap = false;
    bool private swapEnabled = true;

    uint256 public _maxTxAmount = 1000000000 * 10**9;
    uint256 public _maxWalletSize = 2500000000 * 10**9;
    uint256 public _swapTokensAtAmount = 100000000 * 10**9;
    uint256 public _minBuyGame = 10000000 * 10**9;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {

        _tOwned[_msgSender()] = _tTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
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

    // start game
    function openGame() external onlyOwner {
        startGame = true;
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

            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }

            if (!inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapAndPlay(amount);
            }
        }

        bool takeFee = true;

        // If is just a transfer, we don't take fees
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {

            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _taxFee = _taxFeeOnBuy;
                if(amount > _minBuyGame) {
                    latestBuyer = to; // set latest buyer
                }
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _taxFee = _taxFeeOnSell;
            }

        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][swapRouterAddress] < _tokenAmount ) {
            _allowances[address(this)][swapRouterAddress] = type(uint256).max;
            emit Approval(address(this), swapRouterAddress, type(uint256).max);
        }
    }

    // used for LP
    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        approveRouter(_tokenAmount);
        uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, owner(), block.timestamp );
    }
    
    // Let's play a game
    function swapAndPlay(uint256 amount) private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 tokenForLp = 0;

        if(startGame) {
            // latest buyer receive 3/5 from treasury(taxes)
            // SEND THE MONEY TO THE BUYOOOOOR
            uint256 tokenForLastBuyer = _getTax(amount).mul(3).div(5);
            uint verifyUnit = contractTokenBalance.mul(3).div(5);
            if(verifyUnit < tokenForLastBuyer) {
                tokenForLastBuyer = verifyUnit;
            }
            if(latestBuyer != address(0)) {
                _tOwned[latestBuyer] += tokenForLastBuyer;
                _tOwned[address(this)] -= tokenForLastBuyer;
                emit Transfer(address(this), latestBuyer, tokenForLastBuyer);
            }

            // adjust the contract balance
            contractTokenBalance = contractTokenBalance - tokenForLastBuyer;
        }

        bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

        // check if we can send to marketing and LP
        if(canSwap) {
            if(startGame) {
                tokenForLp = _swapTokensAtAmount / 4;
            }
            uint256 tokensToSwap = _swapTokensAtAmount - tokenForLp;
            if(tokensToSwap > 10**9) {
                uint256 ethPreSwap = address(this).balance;
                swapTokensForEth(tokensToSwap);
                uint256 ethSwapped = address(this).balance - ethPreSwap;
                if (tokenForLp > 0 ) {
                    // eth for LP
                    uint256 _ethWeiAmount = ethSwapped.mul(1).div(3);
                    // add to LP :D
                    approveRouter(tokenForLp);
                    addLiquidity(tokenForLp, _ethWeiAmount);
                }
            }
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                sendETHToFee(address(this).balance);
            }
        }

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

    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount);
    }

    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }

    function manualswap() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
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
        uint256 taxAmount = _getTax(tAmount);
        uint256 _transferTotal = tAmount - taxAmount;
        _tOwned[sender] -= tAmount;
        if(taxAmount > 0){
            _tOwned[address(this)] += taxAmount;
        }
        _tOwned[recipient] += _transferTotal;

        emit Transfer(sender, recipient, _transferTotal);
    }

    function _getTax(uint256 tAmount) 
        private
        view
        returns (uint256)
    {
        uint256 tax = tAmount.mul(_taxFee).div(100);
        return tax;
    }

    receive() external payable {}

    function _getCurrentSupply() private view returns (uint256) {
        uint256 tSupply = _tTotal;
        return (tSupply);
    }

    function setFee(uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner {
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

}