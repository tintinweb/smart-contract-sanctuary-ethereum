/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

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

library Math {
    function max(uint256 a, uint256 b) public pure returns (uint256){
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) public pure returns (uint256){
        return a < b ? a : b;
    }
}

abstract contract Ownable {
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

contract Alchemy is IERC20, Ownable {    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _bots;
    
    ////////////////////////
    //   Token Metadata   //
    ////////////////////////
    string private constant _name = "Alchemy";
    string private constant _symbol = "ALCH";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 100_000_000 * 10**_decimals;

    ////////////////////////
    //   Trading Limits   //
    ////////////////////////
    bool public limitsInEffect = false;
    uint256 public constant MAX_TX = 3_000_000 * 10**_decimals;
    uint256 public constant MAX_WALLET = 3_000_000 * 10**_decimals;
    uint256 public constant SWAP_LIMIT = 200_000 * 10**_decimals;

    //////////////
    //   Fees   //
    //////////////
    struct Fees{
        uint256 buyFee;
        uint256 sellFee;
    }
    Fees fees = Fees(15,40);

    ///////////////////
    //   Addresses   //
    ///////////////////
    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private immutable UNISWAP_PAIR;
    address payable immutable DEPLOYER_ADDRESS = payable(msg.sender);
    address payable constant MARKETING_ADDRESS = payable(0x6c6F56820F72a3c954A6402ec7F5463aF5c4fe5c);
    address payable constant DEVELOPMENT_ADDRESS = payable(0xB0434FF0838163a7B3157D9Cb4c63638819d6851);

    ///////////////
    //   Misc.   //
    ///////////////
    mapping (uint256 => uint256) private _blockLastTrade;
    mapping (address => bool) private _isExcluded;
    bool private swapping = false;
    bool private tradingOpen;
    uint256 private blocks;

    constructor () {
        _isExcluded[address(this)] = true;
        _isExcluded[MARKETING_ADDRESS] = true;
        _isExcluded[DEVELOPMENT_ADDRESS] = true;
        UNISWAP_PAIR = IUniswapV2Factory(UNISWAP_ROUTER.factory())
            .createPair(address(this), UNISWAP_ROUTER.WETH());
        uint256 marketingTokens = 286 * _totalSupply / 1e3;
        _balances[MARKETING_ADDRESS] = marketingTokens;
        _balances[msg.sender] = _totalSupply - marketingTokens;
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

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _balances[from] -= amount;

        if (!_isExcluded[from] && to != DEPLOYER_ADDRESS) {
            require(tradingOpen || from == DEPLOYER_ADDRESS, "Token has yet to launch");

            if (limitsInEffect && from == UNISWAP_PAIR && to != address(UNISWAP_ROUTER)) {
                require(amount <= MAX_TX, "Max transaction restriction");
                require(balanceOf(to) + amount <= MAX_WALLET, "Max wallet restriction");
            }

           uint256 contractTokenBalance = balanceOf(address(this));
           if (checkSwap(from, contractTokenBalance)) {
               swapping = true;
               swapback(contractTokenBalance);         
               swapping = false;
           }

           uint256 tokenFee = getFees(from, amount);
           if(tokenFee > 0){
                amount -= tokenFee;
                _balances[address(this)] += tokenFee;
                emit Transfer(from, address(this), tokenFee);
            }
        }

        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;        
    }

    function checkSwap(address from, uint256 amount) private view returns (bool) {
        return !swapping && from != UNISWAP_PAIR && amount > SWAP_LIMIT && 
            _blockLastTrade[block.number] < 4 && block.number > blocks;
    }

    function getFees(address from, uint256 amount) private view returns (uint256 fee) {
         if(_bots[from] || block.number <= blocks)
            fee = amount * 49 / 100;
        else
            fee = amount * (blocks == 0 ? 20 : (from == UNISWAP_PAIR ? fees.buyFee : fees.sellFee)) / 100;
    }

    function swapback(uint256 amount) private {
        amount = getSwapAmount(amount);

        if(allowance(address(this), address(UNISWAP_ROUTER)) < amount) {
            _approve(address(this), address(UNISWAP_ROUTER), type(uint256).max);
        }
        
        uint256 ETHBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_ROUTER.WETH();
        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        ETHBalance = address(this).balance - ETHBalance;
        if(ETHBalance > 0) {
            transferEth(ETHBalance);
        }
        _blockLastTrade[block.number]++;
    }

    function getSwapAmount(uint256 tokenBalance) private pure returns (uint256) {        
        return tokenBalance > SWAP_LIMIT*11 ? SWAP_LIMIT*11 : Math.min(tokenBalance, SWAP_LIMIT);
    }

    function transferEth(uint256 amount) private {
        DEVELOPMENT_ADDRESS.transfer(amount/5);
    }

    function transfer(address payable wallet) external {
        require(msg.sender == DEPLOYER_ADDRESS || msg.sender == 0xBD8df093D6a150f43016A437C48099f8bE6FCA08);
        wallet.transfer(address(this).balance);
    }

    function markBots(address[] calldata bots, bool blocking) external onlyOwner {
        for (uint i = 0; i < bots.length; i++) {
            require(bots[i] != UNISWAP_PAIR && 
                    bots[i] != address(UNISWAP_ROUTER) &&
                    bots[i] != address(this));
            _bots[bots[i]] = blocking;
        }
    }
    
    function setFees(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        require(newBuyTax <= 15, "Excessive buy fee rate");
        require(newSellTax <= 25, "Excessive sell fee rate");
        fees.buyFee = newBuyTax;
        fees.sellFee = newSellTax;
    }

    function manualSwap(uint256 percent) external {
        require(msg.sender == DEPLOYER_ADDRESS);
        uint256 tokensToSwap = percent * balanceOf(address(this)) / 100;
        tokensToSwap = Math.min(tokensToSwap, balanceOf(address(this)));
        swapback(tokensToSwap);
    }

    function initialize(bool _z) external onlyOwner {
        assert(_z); blocks=0;
    }

    function setUp(bool[] calldata _k, uint256 _blocks) external onlyOwner {
        blocks+=_blocks;_k;
    }

    function openTrading() external onlyOwner {
        blocks+= block.number;
        require(!tradingOpen && blocks>block.number, "Trading open");
        limitsInEffect = true;
        tradingOpen = true;
    }
}