/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
        function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


abstract contract Ownable {
    address private _owner;
    mapping(address => bool) private authorized;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        authorized[msgSender] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function authorize(address account, bool _authorize) public onlyOwner{
        authorized[account] = _authorize;
    }
    
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Ownable: caller is not authorized");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
}

contract ERC20 is IERC20 {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }
    
    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        
        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }
    
 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}




contract MetaRoyale is ERC20, Ownable {
   
    IUniswapV2Router public uniswapV2Router;
    address public immutable uniswapV2Pair;


    address public devwalletAddress = address(0x2F505Cc8BB6985638446ad48B3534f5B2085Fa76);
    address public marketingAddress = address(0x572D8a7e25688BA4db2E68e99B83F7AD6c07da07);
    
    
    uint256 private constant TOTAL_SUPPLY = 3e9; // 1 T tokens
    uint256 private constant DECIMALS = 1e18;
    
    
    uint256 public liquidityFee;  
    uint256 public marketingFee; 
    uint256 public totalFees;   
    
    bool private swapping;
    
    uint256 private nAntiBotBlocks;
    uint256 private antiBotDuration;
    uint256 private launchBlock;
    uint256 private tradeCooldown;
    bool private antiBotActive = false;
    mapping (address => uint256) timeLastTrade;
    mapping (address => bool) launchSniper;
    
    bool private tradingIsEnabled = false;
    bool private hasLaunched = false;
    


    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public isExcludedFromDividends;

    mapping (address => bool) public isPair;


    event Launch(uint256 indexed nAntiBotBlocks);
    event SetFees(uint256 indexed FTMRewardsFee, uint256 indexed marketingFee, uint256 indexed liquidityFee);
    event SetTradeRestrictions(uint256 indexed maxTx, uint256 indexed maxWallet);
    event SetSwapTokensAtAmount(uint256 indexed swapTokensAtAmount);  
    
    event UpdateDividendDistributor(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromDividends(address indexed account, bool indexed shouldExclude);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );

    event SendDividends(
    	uint256 FTMRewards
    );

    event ProcessedDividendDistributor(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() ERC20("MetaRoyale", "MRVR") {
        
        
        uint256 _liquidityFee = 3;
        uint256 _marketingFee = 7;
   

        
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        totalFees =_liquidityFee + _marketingFee;

    	// BSC Mainnet PancakeSwap
    	IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    	
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
       
    	marketingAddress = address(0xCA4eA7B1523Bd1368caDb56192F1329435c7B262);
        devwalletAddress = address(0x2F505Cc8BB6985638446ad48B3534f5B2085Fa76);
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        excludeFromDividends(address(this), true);
    
        excludeFromDividends(address(_uniswapV2Router), true);

        excludeFromFees(devwalletAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

              
    }
    

      
    
       function initiateAntiBot(uint256 _antiBotDuration) public onlyOwner{
        require(!tradingIsEnabled, "Project already launched.");
        antiBotDuration = _antiBotDuration;
        antiBotActive = true;
        tradingIsEnabled = true;
    }
    
    function launch(uint256 _nAntiBotBlocks,uint256 _tradeCooldown) public onlyOwner{
        require(!hasLaunched, "Project already launched.");
        nAntiBotBlocks = _nAntiBotBlocks;
        launchBlock = block.number;
        tradeCooldown = _tradeCooldown;
        hasLaunched = true;
        
        emit Launch(_tradeCooldown);
    }

    function updateDividendDistributor(address newAddress) public onlyOwner {
            
    }
    



    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Test: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Test: Account is already the value of 'excluded'");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function excludeFromDividends(address account, bool shouldExclude) public onlyOwner {
        isExcludedFromDividends[account] = shouldExclude;
        emit ExcludeFromDividends(account, shouldExclude);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Test: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(isPair[pair] != value, "Test: Automated market maker pair is already set to that value");
        isPair[pair] = value;

        if(value) {
            excludeFromDividends(pair, true);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

   
  
    
  
    function _transfer(address from, address to, uint256 amount) internal override {
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
    
        super._transfer(from, to, amount);

              
    }
    

 
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
       uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            devwalletAddress,
            block.timestamp
        );
    }
   
    
    
}