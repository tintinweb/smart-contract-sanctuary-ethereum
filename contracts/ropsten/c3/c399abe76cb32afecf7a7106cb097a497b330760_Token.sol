/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;
//算法調用
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
//調用接口
interface IERC20 {
    function totalSupply() external view returns (uint256); //總供應量
    function balanceOf(address account) external view returns (uint256); //餘額查詢
    function transfer(address recipient, uint256 amount) external returns (bool); //轉移資產
    function allowance(address owner, address spender) external view returns (uint256); //返回指定地址還能從owner中提取代幣的餘額
    function approve(address spender, uint256 amount) external returns (bool);  //設置當前賬戶對指定賬戶的允許轉賬值
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);   //由指定發送地址香指定接收地址發送一定量的token，一定要觸發transfer事件，如果發起放token不足，會發出should函數
    event Transfer(address indexed from, address indexed to, uint256 value);    //token交易時觸發
    event Approval(address indexed owner, address indexed spender, uint256 value);  //approve函數調用時觸發
}
abstract contract Context {
    //獲取擁有者地址
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    //所有權轉移事件
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() internal {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    //放棄擁有權
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private _name = "cktestro";
    string private _symbol = "cktestro";
    uint8  private _decimals = 18;
    uint256 private _totalSupply = 1000000 * 10**18;
    uint256 public  _tTaxFeeTotal;
    uint256 private _revenueFee = 2;
    uint256 private _previousTaxFee = _revenueFee;
    uint256 private _destroyFee = 2;
    uint256 private _previousElseFee = _destroyFee;
    uint256 private _ranshaoFee = 2;
    uint256 private _spareRanshaoFee = _ranshaoFee;
    mapping (address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public burnAddress = address(0x000000000000000000000000000000000000dEaD);
    address public mainAddres = address(0x177849b19d0B1aFeA500b1dF4b0364267570aF32); //主要地址
    address public marketAddress = address(0x0E06501daE5CDBdDb3e080C1824b1D20be0478Ce); //营收地址
    address public liquidityWallet = address(0x35c357b59b17283bbC09ca25D314e2b2F890b942);//流動池地址

    constructor () public {
        _balances[mainAddres] = _balances[mainAddres].add(_totalSupply);
        emit Transfer(address(0), mainAddres, _totalSupply);
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return 18;
    }
    //總供應量
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
        function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    //分配金額
    function _distribution(uint256 allamount) private view returns (uint256, uint256, uint256, uint256){
        //分配銷燬金額
       uint256 _destroyAmount = allamount.mul(_destroyFee).div(100);
        //分配營收金額
       uint256 _marketAmount = allamount.mul(_revenueFee).div(100);
        //分配流動池燃燒金額
       uint256 _ranshao = allamount.mul(_ranshaoFee).div(100);
        //分配玩家總所得額度
       uint256 _actualAmount = allamount.sub(_destroyAmount).sub(_marketAmount);
        return (_actualAmount, _destroyAmount, _ranshao, _marketAmount);
    }
    //總賬戶轉給玩家賬戶,銷燬，營收
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        (uint256 _actualAmount, uint256 _destroyAmount, uint256 _ranshao, uint256 _marketAmount) = _distribution(amount);
        _transfer(_msgSender(), recipient, _actualAmount);
        _burn(_msgSender(), _destroyAmount);
        _ranShao(liquidityWallet, _ranshao);
        _gotomarket(_msgSender(), _marketAmount);
        return true;
    }
    //玩家之間轉賬,銷燬，營收
    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        (uint256 _actualAmount, uint256 _destroyAmount, uint256 _ranshao, uint256 _marketAmount) = _distribution(amount);
        _transfer(sender, recipient, _actualAmount);
        _burn(_msgSender(), _destroyAmount);
        _ranShao(liquidityWallet, _ranshao);
        _gotomarket(_msgSender(), _marketAmount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    //打入黑洞2%
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, burnAddress, amount);
    }
    //營收2%
    function _gotomarket(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: gotomarket from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: gotomarket amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, marketAddress, amount);
    }
    //流動池跟隨交易燃燒，每筆2%
    function _ranShao(address account, uint256 amount) internal virtual {
        if (account != mainAddres && account != address(0) && account != burnAddress) {
            _balances[account] = _balances[account].sub(amount, "ERC20: ranshao amount exceeds balance");
            _totalSupply = _totalSupply.sub(amount);
            emit Transfer(account, burnAddress, amount);        
        }
    }
    //接口更新流動池子錢包地址
    function changeLiquidityWallet(address newLiquidityWallet) public onlyOwner{
        if(newLiquidityWallet != mainAddres && newLiquidityWallet !=address(0) &&  newLiquidityWallet != burnAddress){
            liquidityWallet = newLiquidityWallet;
        }
    }
    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    //owner是物主的意思
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    receive() external payable {}
    // function _approve(address owner, address spender, uint256 amount) private {
    //     require(owner != address(0), "ERC20: approve from the zero address");
    //     require(spender != address(0), "ERC20: approve to the zero address");
    //     _allowances[owner][spender] = amount;
    //     emit Approval(owner, spender, amount);
    // }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        _balances[from] = _balances[from].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }
    // function _transfer(address sender,address recipient,uint256 amount) internal virtual {
    //     require(sender != address(0), "ERC20: transfer from the zero address");
    //     require(recipient != address(0), "ERC20: transfer to the zero address");
    //     _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    //     _balances[recipient] = _balances[recipient].add(amount);
    //     emit Transfer(sender, recipient, amount);
    // }

}