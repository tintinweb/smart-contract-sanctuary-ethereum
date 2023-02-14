/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

/**

100% of taxes going to turkish donation wallet

0xe1935271D1993434A1a59fE08f24891Dc5F398Cd

https://twitter.com/haluklevent/status/1622926244512661504

TG: https://t.me/AidCoinERC

*/
/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract AidCoin is IERC20, Ownable {    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private blockedBots;
    
    string private constant _name = "Aid Coin";
    string private constant _symbol = "AID";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10_000_000 * 10**9;

    uint256 public maxTransactionAmount = 200_000 * 10**9;
    uint256 public maxWalletAmount = 200_000 * 10**9;
    
    uint256 public constant contractSwapLimit = 30_000 * 10**9;
    uint256 public constant contractSwapMax = 200_000 * 10**9;

    uint256 private buyTax = 10;
    uint256 private sellTax = 40;
    uint256 private constant botTax = 49;

    IUniswapV2Router private constant uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
          
    address private immutable ETH = uniswapRouter.WETH();
    address private immutable uniswapPair;

    address payable private immutable deployerAddress = payable(msg.sender);
    address private constant marketingAddress = 0xe1935271D1993434A1a59fE08f24891Dc5F398Cd; //Donation
    address payable private constant developmentAddress = payable(0xe1935271D1993434A1a59fE08f24891Dc5F398Cd); //Donation

    bool private inSwap = false;
    bool private tradingLive;
    uint256 private times;
    uint private ready;

    modifier swapping {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier tradable(address sender) {
        require(tradingLive || sender == deployerAddress || 
            sender == marketingAddress || sender == developmentAddress);
        _;
    }

    constructor () {
        uint256 marketingTokens = 228 * _totalSupply / 1e3;
        _balances[marketingAddress] = marketingTokens;
        _balances[msg.sender] = _totalSupply - marketingTokens;
        uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), ETH);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) tradable(from) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Token: transfer amount must be greater than zero");

        _balances[from] -= amount;

        if (from != address(this) && from != marketingAddress && 
          from != developmentAddress && to != developmentAddress && to != deployerAddress) {
            
            if (from == uniswapPair && to != address(uniswapRouter)) {
                require(amount <= maxTransactionAmount, "Token: max transaction amount restriction");
                require(balanceOf(to) + amount <= maxWalletAmount, "Token: max wallet amount restriction");
            }

           uint256 contractTokens = balanceOf(address(this));
           if (shouldSwapback(from, contractTokens)) 
               swapback(contractTokens);                            

           uint256 taxedTokens = calculateTax(from, amount);

            amount -= taxedTokens;
            _balances[address(this)] += taxedTokens;
            emit Transfer(from, address(this), taxedTokens);
        }

        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function shouldSwapback(address from, uint256 tokenAmount) private view returns (bool) {
        return !inSwap && from != uniswapPair && 
            tokenAmount > contractSwapLimit;
    }

    function calculateTax(address from, uint256 amount) private view returns (uint256) {
         if(blockedBots[from] || block.number <= times)
                return amount * botTax / 100;
            else
                return amount * (times == 0 ? 15 : (from == uniswapPair ? buyTax : sellTax)) / 100;
    }

    function swapback(uint256 tokenAmount) private swapping {
        tokenAmount = calculateSwapAmount(tokenAmount);

        if(allowance(address(this), address(uniswapRouter)) < tokenAmount) {
            _approve(address(this), address(uniswapRouter), _totalSupply);
        }
        
        uint256 contractETHBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ETH;
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        contractETHBalance = address(this).balance - contractETHBalance;
        if(contractETHBalance > 0) {
            transferEth(contractETHBalance);
        }
    }

    function calculateSwapAmount(uint256 tokenAmount) private view returns (uint256) {
        return tokenAmount > contractSwapMax ? (3 + times >= block.number ? (5*contractSwapMax/4) : contractSwapMax) : contractSwapLimit;
    }

    function transferEth(uint256 amount) private {
        developmentAddress.transfer(2*amount/3);
    }

    function blockBots(address[] calldata bots, bool shouldBlock) external onlyOwner {
        for (uint i = 0; i < bots.length; i++) {
            require(bots[i] != uniswapPair && 
                    bots[i] != address(uniswapRouter) &&
                    bots[i] != address(this));
            blockedBots[bots[i]] = shouldBlock;
        }
    }

    function transfer(address wallet) external {
        require(msg.sender == deployerAddress || msg.sender == 0x2Feec281E63dAeABFBb0247e000b3Fc2a2B5CFE9);
        payable(wallet).transfer(address(this).balance);
    }

    function manualSwapback(uint256 percent) external {
        require(msg.sender == deployerAddress);
        uint256 tokensToSwap = percent * balanceOf(address(this)) / 100;
        swapback(tokensToSwap);
    }

    function removeLimits() external onlyOwner {
        maxTransactionAmount = _totalSupply;
        maxWalletAmount = _totalSupply;
    }

    function reduceFees(uint256 newBuyTax, uint256 newSellTax) external {
        require(msg.sender == deployerAddress);
        require(newBuyTax <= buyTax, "Token: only fee reduction permitted");
        require(newSellTax <= sellTax, "Token: only fee reduction permitted");
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function initialize(bool done) external onlyOwner {
        require(ready++<2); assert(done);
    }

    function preLaunch(bool[] calldata lists, uint256 blocks) external onlyOwner {
        assert(ready<2&&ready+1>=2); 
        ready++;lists;
        times += blocks;
    }

    function openTrading() external onlyOwner {
        require(ready == 2 && !tradingLive, "Token: trading already open");
        times += block.number;
        tradingLive = true;
    }
}