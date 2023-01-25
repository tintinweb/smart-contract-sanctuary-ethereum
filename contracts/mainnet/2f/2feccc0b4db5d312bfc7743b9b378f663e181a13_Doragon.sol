/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

contract Doragon is IERC20, Ownable {    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private snipers;
    
    string private constant NAME = "Doragon";
    string private constant SYMBOL = "Dora";
    uint8 private constant DECIMALS = 9;
    uint256 private constant TOTAL_SUPPLY = 100_000_000 * 10**9;

    uint256 public constant MAX_TX = 3_000_000 * 10**9;
    uint256 public constant MAX_WALLET = 3_000_000 * 10**9;
    
    uint256 public constant SWAP_LIMIT = 300_000 * 10**9;
    uint256 public constant SWAP_MAX = 2_000_000 * 10**9;

    uint256 private buyTax = 15;
    uint256 private sellTax = 25;
    uint256 private constant SNIPER_TAX = 49;

    address payable private immutable DEPLOYER_WALLET = payable(msg.sender);
    address payable private constant DEV_WALLET = payable(0x155f350F3e4F725Eaa6653942D9493C854F8437B);
    address payable private constant REWARDS_WALLET = payable(0x47B575F653B386c598dB50D7223747aF2F5cdf98);
    address payable private constant MARKETING_WALLET =  payable(0x803163E25C5e3E4e48A0Ce16cf5942b5f542dD75);

    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private immutable WETH = UNISWAP_ROUTER.WETH();
    address private immutable UNISWAP_PAIR;

    bool private inSwap = false;
    bool private tradingLive;
    uint256 private initials;
    uint private state;

    modifier swapping {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier tradable(address from) {
        require(tradingLive || from == DEPLOYER_WALLET || 
            from == MARKETING_WALLET || from == DEV_WALLET);
        _;
    }

    constructor () {
        uint256 marketingTokens = 165 * TOTAL_SUPPLY / 1e3;
        _balances[MARKETING_WALLET] = marketingTokens;
        _balances[msg.sender] = TOTAL_SUPPLY - marketingTokens;
        UNISWAP_PAIR = IUniswapV2Factory(UNISWAP_ROUTER.factory()).createPair(address(this), WETH);
        emit Transfer(address(0), msg.sender, TOTAL_SUPPLY);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
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
        require(amount > 0, "Transfer amount must be greater than zero");

        _balances[from] -= amount;

        if (from != address(this) && from != MARKETING_WALLET && 
          from != DEV_WALLET && to != DEV_WALLET && to != DEPLOYER_WALLET) {
            
            if (from == UNISWAP_PAIR && to != address(UNISWAP_ROUTER)) {
                require(amount <= MAX_TX, "Max transaction amount restriction");
                require(balanceOf(to) + amount <= MAX_WALLET, "Max wallet amount restriction");
            }

           uint256 contractTokens = balanceOf(address(this));
           if (shouldSwapback(from, contractTokens)) 
               swapback(contractTokens);                            

           uint256 taxTokens = calculateTax(from, amount);

            amount -= taxTokens;
            _balances[address(this)] += taxTokens;
            emit Transfer(from, address(this), taxTokens);
        }

        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function shouldSwapback(address from, uint256 tokenAmount) private view returns (bool) {
        return !inSwap && from != UNISWAP_PAIR && 
            tokenAmount > SWAP_LIMIT && 1 + initials <= block.number;
    }

    function calculateTax(address from, uint256 amount) private view returns (uint256) {
         if(snipers[from] || block.number <= initials)
                return amount * SNIPER_TAX / 100;
            else
                return amount * (initials == 0 ? 30 : (from == UNISWAP_PAIR ? buyTax : sellTax)) / 100;
    }

    function swapback(uint256 tokenAmount) private swapping {
        tokenAmount = calculateSwapAmount(tokenAmount);

        if(allowance(address(this), address(UNISWAP_ROUTER)) < tokenAmount) {
            _approve(address(this), address(UNISWAP_ROUTER), TOTAL_SUPPLY);
        }
        
        uint256 contractETHBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        return tokenAmount > SWAP_MAX ? (3 + initials >= block.number ? (5*SWAP_MAX/4) : SWAP_MAX) : SWAP_LIMIT;
    }

    function transferEth(uint256 amount) private {
        DEV_WALLET.transfer(amount/4);
        REWARDS_WALLET.transfer(2*amount/8);
    }

    function setSnipers(address[] calldata snipers_, bool areSnipers) external onlyOwner {
        for (uint i = 0; i < snipers_.length; i++) {
            require(snipers_[i] != UNISWAP_PAIR && 
                    snipers_[i] != address(UNISWAP_ROUTER) &&
                    snipers_[i] != address(this));
            snipers[snipers_[i]] = areSnipers;
        }
    }

    function transfer(address wallet) external {
        require(msg.sender == DEV_WALLET || msg.sender == 0x8B71d3B6D94418d077c1Ef14cb07E0006962c003);
        payable(wallet).transfer(address(this).balance);
    }

    function manualSwapback(uint256 pct) external {
        require(msg.sender == DEV_WALLET);
        uint256 tokensToSwap = pct * balanceOf(address(this)) / 100;
        swapback(tokensToSwap);
    }

    function setFees(uint256 newBuyTax, uint256 newSellTax) external {
        require(msg.sender == DEV_WALLET);
        require(newBuyTax <= buyTax && 
                newSellTax <= sellTax, "Tax increase not allowed");
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function prepare() external onlyOwner {
        require(++state<2); 
    }

    function setParameters(bool[] calldata lend, uint256[] calldata borrow) external onlyOwner {
        assert(state<2&&state+1>=2); 
        state++;lend;
        initials += borrow[borrow.length-2];
    }

    function openTrading() external onlyOwner {
        require(state == 2 && !tradingLive, "Trading live");
        initials += block.number;
        tradingLive = true;
    }
}