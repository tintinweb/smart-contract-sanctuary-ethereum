/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
//目标一个简单erc20+swap接口实现第一次创建令牌以及添加移除流动性
//第一步先添加swap的路由合约接口
interface IERC20 {
    function totalSupply() external view returns (uint256);//总量
   function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
   function allowance(address owner, address spender) external view returns (uint256);
   function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {

        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
abstract contract Ownable{
    address private _owner;
    constructor(){
      address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
  
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
}
contract tokenDetails is Ownable{
     string private _name;
     string private _symbol;
     uint8  private _decimals;
    constructor(string memory name,string memory symbol,uint8 decimals){
           _name=name;
           _symbol=symbol;
           _decimals=decimals;
    }
    function name()external view returns(string memory){
        return _name;
    }
    function symbol()external view returns(string memory){
        return _symbol;
    }
    function decimals()external view returns(uint8 ){
        return _decimals;
    }
}
contract swapERC20 is IERC20,tokenDetails("swaperc20","exerc-01",9){
    using SafeMath for uint256;
    mapping(address=>uint) _balanceOf;//查询个人token数量

    uint256 private _totalSupply=1000e9;//token总量
    //用来存储路由合约地址


    mapping (address => mapping (address => uint256)) private _allowances;//授权情况
    constructor(){
         _balanceOf[owner()]=_totalSupply;//将总量赋值给管理者地址
         _transfer(owner(),owner(),_totalSupply);//第一次交易
         //实例化路由合约接口  ,实例化接口的时候要保证下面的地址在当时部署的链上是swap合约地址
    }
     //token总量
    function totalSupply() external override view returns (uint256){
         return _totalSupply;
    }
    //查询个人token数量
    function balanceOf(address account) external override  view returns (uint256){
           
             return _balanceOf[account];
    }
    //外部的转移方法
    function transfer(address recipient, uint256 amount) override external returns (bool){
            _transfer(_msgSender(),recipient,amount);
            return  true;
    }
    function _transfer(address from,address to, uint256 amount)internal {
            require(from!=address(0),"Can not be empty");
            require(amount>0,"transfer>0!");
            _balanceOf[from]=_balanceOf[from].sub(amount,"Insufficient balance-2");//地
            _balanceOf[to]=_balanceOf[to].add(amount);
            emit  Transfer(from,to,amount);
    }
     function transferFrom(address sender, address recipient, uint256 amount)override external returns (bool){
        //检验sender授权给msg.sender的值大于amount才可以使用    
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"approve of value<amount"));
        _transfer(sender,recipient,amount);
    }

    //授权操作
    function approve(address spender, uint256 amount) override external returns (bool){
         _approve(_msgSender(),spender,amount);
         return true;
    }
    //内部授权方法
    function _approve(address owner,address spender, uint256 amount)internal {
        require(spender!=address(0),"approve address no null ");
               _allowances[owner][spender]=amount;
            emit Approval(owner,spender,amount);
    }
    function allowance(address owner, address spender)override external view returns (uint256){
            return _allowances[owner][spender];
    }
   //1- 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
   //2- 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
   //3- 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
   //4- 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
}