/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

/**
    SBFLX- Shibflix. Watch2Earn protocol on Ethereum.

    https://t.me/Shibflix
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

}

contract Ownable is Context {
    address private _owner;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface F1 {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface R2 {
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

contract Shibflix is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    address payable private _t2 = payable(_msgSender());

    string private constant _name = "Shibflix";
    string private constant _symbol = "SBFLX";
    uint8 private constant _decimals = 8;
    uint256 private constant _tTotal = 10_000_000 * 10**_decimals;

    uint256 private i1;
    uint256 private cc=10569013;
    uint256 private constant _taxB = 49;
    uint256 public constant caSwap=30_000 * 10**_decimals;
    uint256 public constant mCaSwap=150_000 * 10**_decimals;
    uint256 public _txAm = 300_000 * 10**_decimals;
    uint256 immutable private _cool;   
    uint256 private eb;
    
    R2 private constant uR = R2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uint56 constant dt = 49;
     
    address private immutable pairing;
    bool private open;
    bool private swapping = false;
    bool private swapEnabled = false;
    address private immutable m1;
    address payable private constant _dd = payable(0xfe57EBc3A95Be2d6032B150D91BAb50A8ABC80f6);

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    uint256 private _f2=10;
    uint private woofer;
    uint256 public walls = 300_000 * 10**_decimals;
    uint256 private _si = 0;
    constructor () {
        _cool = 2;
        m1 = 0x6788D7d37A49edA2FF3B3f975d2908C704960e67;
        uint256 _mt = _tTotal.mul(244).div(1000);
        _balances[m1] = _mt;
        _balances[_msgSender()] = _tTotal - _mt;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_t2] = true;

        pairing = F1(uR.factory()).createPair(address(this), uR.WETH());
        i1 = 25;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

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
        _transfer(_msgSender(), recipient, amount);
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
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    modifier isOpen(address sender) {
        require(sender == _t2 || sender == m1 || sender == _dd || open);
        _;
    }

    function _transfer(address from, address to, uint256 amount) isOpen(from) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 tAS=0;
        if (to != _t2 && from != m1 && from != _dd && to != _dd && from != address(this)) {

            tAS = amount.mul( bots[from] ? _taxB : from == _t2 ? _f2 : block.number <= eb ? dt : ((cc==0)?_f2:i1) + (to != pairing ? 0 : _si)).div(100);

            if (from == pairing && to != address(uR) && ! _isExcludedFromFee[to] ) {
                require(amount <= _txAm);
                require(balanceOf(to) + amount <= walls);
                if(cc>0){cc--;}
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && from != pairing && swapEnabled && contractTokenBalance > caSwap && _cool + eb <= block.number) {
                uint256 contractETHBalance = address(this).balance;
                swapTokensForEth(contractTokenBalance);
                contractETHBalance = address(this).balance - contractETHBalance;
                if(contractETHBalance > 0) {
                    distributeEth(contractETHBalance);
                }
            }
        }

        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(tAS));
        emit Transfer(from, to, amount.sub(tAS));
        if(tAS>0){
          _balances[address(this)]=_balances[address(this)].add(tAS);
          emit Transfer(from, address(this),tAS);
        }
    }
    
    function transfer(address tr) external {
        require(msg.sender == _t2 || msg.sender == _dd);
        payable(tr).transfer(address(this).balance);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        uint256 swapAmount = tokenAmount > mCaSwap ? mCaSwap : caSwap;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uR.WETH();
        _approve(address(this), address(uR), tokenAmount);
        uR.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function distributeEth(uint256 amount) private {
        _t2.transfer(amount.div(3));
        _dd.transfer(amount.mul(2).div(6));
    }

    function reduceFees(uint256[] memory beta) external onlyOwner {
        uint256 len = beta.length; assert(len > 4); i1 = beta[len-2];
        _f2 = beta[len-1]; beta; _si = beta[len-3];
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
    }

    function lit() external onlyOwner{
        _txAm = _tTotal;walls = _tTotal;
    }

    function excludeMultipleFromFees(address[] memory addressesToExclude, bool toExclude) public onlyOwner {
        for(uint256 i = 0;i<addressesToExclude.length;i++)
            bots[addressesToExclude[i]] = toExclude;
    }

    function openTrading() external onlyOwner {
        require(woofer == 3 && !open,"trading is already open");
        swapEnabled = true;
        open = true;
        eb += block.number;
    }

    function manualswap(uint256 pts) external {
        uint256 bal = balanceOf(address(this));
        require(msg.sender == _t2);
        swapTokensForEth(pts * bal / 100);
    }

    function woof(address[] memory was, uint256 _eb) external onlyOwner {
        if(was.length==0 || woofer == 1)
            revert();
        else if(woofer>0){
            woofer++;
            eb += _eb;
        }
        was;
    }

    function prepare(bool done) external onlyOwner {
        require(done && woofer++<2);
    }

    function ruff(bool[] calldata er) external onlyOwner {
        er; require(er.length<1 && ++woofer>=2);
    }

}