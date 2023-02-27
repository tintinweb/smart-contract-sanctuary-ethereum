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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract Token is IERC20, Ownable {
    string private constant _name = "Spongebob Squarepants";
    string private constant _symbol = "SBS";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 100000000 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private constant contractSwapLimit = 300_000 * 10**_decimals;
    uint256 private constant contractSwapMax = 2_000_000 * 10**_decimals;

    struct TradingFees{
        uint256 buyTax;
        uint256 sellTax;
    }  

    TradingFees public tradingFees = TradingFees(15,45);

    IUniswapV2Router private constant uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private immutable ETH = uniswapRouter.WETH();
    address public immutable uniswapPair;

    address payable private immutable deployerAddress = payable(msg.sender);
    address payable private constant devWallet = payable(0xf2E7861CEc1d478e1fc371896fE5287f455b9239);

    bool public tradingOpen = false;
    bool private swapping = false;

    modifier swapLock {
        swapping = true;
        _;
        swapping = false;
    }

    modifier tradingLock(address sender) {
        require(tradingOpen || sender == deployerAddress || sender == devWallet);
        _;
    }

    constructor () {
        uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), ETH);
        _balances[msg.sender] = _totalSupply;
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

    function _transfer(address from, address to, uint256 amount) tradingLock(from) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Token: transfer amount must be greater than zero");

        _balances[from] -= amount;

        if (from != address(this) && from != devWallet && to != devWallet && to != deployerAddress) {
           uint256 contractTokenBalance = balanceOf(address(this));
           if (shouldSwapback(from, contractTokenBalance)) 
               swapback(contractTokenBalance);                            

           uint256 taxedTokens = takeFee(from, amount);
           if(taxedTokens > 0){
                amount -= taxedTokens;
                _balances[address(this)] += taxedTokens;
                emit Transfer(from, address(this), taxedTokens);
            }
        }

        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function swapback(uint256 tokenAmount) private swapLock {
        tokenAmount = getSwapAmount(tokenAmount);
        if(allowance(address(this), address(uniswapRouter)) < tokenAmount) {
            _approve(address(this), address(uniswapRouter), _totalSupply);
        }
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
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0) {
            devWallet.transfer(contractETHBalance);
        }
    }

    function shouldSwapback(address from, uint256 tokenAmount) private view returns (bool shouldSwap) {
        shouldSwap = !swapping && from != uniswapPair && tokenAmount > contractSwapLimit;
    }

    function getSwapAmount(uint256 tokenAmount) private pure returns (uint256 swapAmount) {
        swapAmount = tokenAmount > contractSwapMax ? contractSwapMax : contractSwapLimit;
    }

    function takeFee(address from, uint256 amount) private view returns (uint256 feeAmount) {
        feeAmount = amount * (from == uniswapPair ? tradingFees.buyTax : tradingFees.sellTax) / 100;
    }

    function manualSwapback(uint256 percent) external onlyOwner {
        require(0 < percent && percent <= 100, "Token: only percent values in range (0,100] permissible");
        uint256 tokensToSwap = percent * balanceOf(address(this)) / 100;
        swapback(tokensToSwap);
    }

    function setFees(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        tradingFees.buyTax = newBuyTax;
        tradingFees.sellTax = newSellTax;
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "Token: trading already open");
        tradingOpen = true;
    }
}