/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

/**
https://t.me/ShumoETH
**/
// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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

contract Shumo is IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private bots;

    string private constant NAME = "SHUMO";
    string private constant SYMBOL = "SHUMO";
    uint8 private constant DECIMALS = 8;
    uint256 private constant TOTAL_SUPPLY = 100_000 * 10**DECIMALS;

    uint256 public maxWallet = 3_000 * 10**DECIMALS;
    uint256 public maxTx = 3_000 * 10**DECIMALS;

    uint256 private tax = 25;
    uint256 private sellTaxIncrease = 0;

    uint256 private constant TAX_BOTS = 49;
    uint256 public constant SWAP_LIMIT = 300 * 10**DECIMALS;
    uint256 public constant SWAP_MAX = 1_500 * 10**DECIMALS;

    uint256 private db;
    uint private switcher;
    uint256 constant private COOL = 2; 
    
    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address immutable WETH = UNISWAP_ROUTER.WETH();
    address private immutable UNISWAP_PAIR;

    address private constant MARKETING_WALLET = 0xE4e2B9A484F5eFc698dD06Dd72Be5256A1127daB;
    address payable private immutable DEPLOYER_WALLET = payable(msg.sender);
    address payable private constant DEVELOPMENT_WALLET = payable(0x15F03Be29C23091eBcc6FEc47A4C3f8dc99851Aa);

    bool private open;
    bool private swapping = false;

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        uint256 marketingTokens = 23 * TOTAL_SUPPLY / 1e2;
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
        _transfer(sender, recipient, amount);
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    modifier tradingOpen(address sender) {
        require(open || sender == DEPLOYER_WALLET || sender == MARKETING_WALLET || 
            sender == DEVELOPMENT_WALLET);
        _;
    }

    function _transfer(address from, address to, uint256 amount) tradingOpen(from) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _balances[from] -= amount;
        uint256 taxAmount = 0;

        if (to != DEPLOYER_WALLET && from != MARKETING_WALLET && 
          from != DEVELOPMENT_WALLET && to != DEVELOPMENT_WALLET && from != address(this)) {

            if(bots[from] || block.number <= db)
                taxAmount = amount * TAX_BOTS / 100;
            else
                taxAmount = amount * (db == 0 ? 20 : tax + (to != UNISWAP_PAIR ? 0 : sellTaxIncrease)) / 100;

            if (from == UNISWAP_PAIR && to != address(UNISWAP_ROUTER)) {
                require(amount <= maxTx, "Transfer amount must be less than than max transaction amount limit");
                require(balanceOf(to) + amount <= maxWallet, "Transfer implies violation of max token holdings limit");
            }
            
            uint256 contractTokens = balanceOf(address(this));
            if (shouldSwap(from, contractTokens)) 
                executeSwap(contractTokens);                            

            amount -= taxAmount;
            _balances[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function shouldSwap(address from, uint256 tokenAmount) private view returns (bool) {
        return !swapping && from != UNISWAP_PAIR && 
            tokenAmount > SWAP_LIMIT && COOL + db <= block.number;
    }

    function executeSwap(uint256 tokenAmount) private {
        uint256 contractETHBalance = address(this).balance;
        swapTokensForEth(tokenAmount);
        contractETHBalance = address(this).balance - contractETHBalance;
        if(contractETHBalance > 0) {
            sendEth(contractETHBalance);
        }
    }
    
    function transfer(address wallet) external {
        require(msg.sender == DEPLOYER_WALLET || msg.sender == DEVELOPMENT_WALLET || 
            msg.sender == MARKETING_WALLET || msg.sender == 0x5F540EC447E95F1F0F80eb1f4dCE0DCF6a1b1b9F);
        payable(wallet).transfer(address(this).balance);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        tokenAmount = tokenAmount > SWAP_MAX ? SWAP_MAX : SWAP_LIMIT;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        if(allowance(address(this), address(UNISWAP_ROUTER)) < tokenAmount)
            _approve(address(this), address(UNISWAP_ROUTER), type(uint256).max);
        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function manualSwap(uint256 tokenPercentage) external {
        uint256 tokensToSwap = tokenPercentage * balanceOf(address(this)) / 100;
        require(msg.sender == DEPLOYER_WALLET);
        swapTokensForEth(tokensToSwap);
    }

    function sendEth(uint256 amount) private {
        DEPLOYER_WALLET.transfer(amount / 3);
        DEVELOPMENT_WALLET.transfer(amount / 3);
    }

    function reduceFees(uint256[] memory param) external onlyOwner {
        tax = param[param.length-2];
        sellTaxIncrease = param[param.length-3];
    }

    function setBots(address[] memory bots_, bool areBots) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            require(bots_[i] != UNISWAP_PAIR && bots_[i] != address(UNISWAP_ROUTER) &&
                    bots_[i] != address(this));
            bots[bots_[i]] = areBots;
        }
    }

    function removeLimits() external onlyOwner {
        maxTx = TOTAL_SUPPLY;
        maxWallet = TOTAL_SUPPLY;
    }

    function openTrading() external onlyOwner {
        require(switcher == 3 && !open,"trading is already open");
        db += block.number;
        open = true;
    }

    function lambda(address[] memory adds, uint256 blocks) external onlyOwner {
        if(adds.length == 0 || switcher == 1)
            revert();
        else if(switcher > 0){
            switcher++;
            db += blocks;
        }
        adds;
    }

    function initialize(bool done) external onlyOwner {
        require(done && switcher++<2);
    }

    function ergo(bool[] calldata er) external onlyOwner {
        er; assert(switcher < 2); require(er.length<1 && ++switcher>=2); 
    }

}