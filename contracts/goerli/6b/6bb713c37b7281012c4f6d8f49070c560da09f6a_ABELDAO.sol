/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-06
*/

/*

_____/\\\\\\\\\__________________________________/\\\\____________/\\\\______________________________        
 ___/\\\\\\\\\\\\\_______________________________\/\\\\\\________/\\\\\\______________________________       
  __/\\\/////////\\\___/\\\\\\\\\_________________\/\\\//\\\____/\\\//\\\______________________________      
   _\/\\\_______\/\\\__/\\\/////\\\_____/\\\\\\\\__\/\\\\///\\\/\\\/_\/\\\_____/\\\\\\\\___/\\\____/\\\_     
    _\/\\\\\\\\\\\\\\\_\/\\\\\\\\\\____/\\\/////\\\_\/\\\__\///\\\/___\/\\\___/\\\/////\\\_\///\\\/\\\/__    
     _\/\\\/////////\\\_\/\\\//////____/\\\\\\\\\\\__\/\\\____\///_____\/\\\__/\\\\\\\\\\\____\///\\\/____   
      _\/\\\_______\/\\\_\/\\\_________\//\\///////___\/\\\_____________\/\\\_\//\\///////______/\\\/\\\___  
       _\/\\\_______\/\\\_\/\\\__________\//\\\\\\\\\\_\/\\\_____________\/\\\__\//\\\\\\\\\\__/\\\/\///\\\_ 
        _\///________\///__\///____________\//////////__\///______________\///____\//////////__\///____\///__

ABEL DAO愿景：建立一个以人为本的价值网络，人人数据自治，所有资产合数据归个人所有，没有人和机构可以侵犯和剥削。
        建立一个自我激励的经济组织，分布式的经济体系和民主化的管理，将技术、资本和人力资源有机结合起来，帮助社区组织的每个成员利益最大化。
        使命：受任于危、奉命于坚、倾己之力、成彼（币）之道（DAO）
        运作机制：持有AD代币即为社区成员，享有社区投票权利。选举委员会，成立基金会，每笔交易8%注入基金会钱包。基金会将会把税收投入到以web3.0为主导的生态，创造价值反哺社区，实现生态自治。
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b); 
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
contract ABELDAO {
  using SafeMath for uint;
  string public symbol;
  string public  name;
  uint8 public decimals;
  uint _totalSupply;
  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint)) allowed;
  address public uniswapV2Pair;
  uint256 maxnum ;
  IUniswapV2Router02  uniswapV2Router;
  //锁仓多少区块（按区块线性释放）
  uint256 locktime1 = 52560000;
  uint256 locktime2 = 288000;
  //开始释放区块
  uint256 lockstart1 = 15000000;
  uint256 lockstart2 = 15000000;
  //基金钱包地址
  address vaultAddr = 0xebd03CEa0Fd747A0504Aee1B47CE614348ed8d96;
  //流回比例(除以1000)
  uint256 fee = 80;
  address owner;
  mapping (address => User) users;
  struct User{
    uint256 locktime;
    uint256 lockstart;
    uint256 lockamount;
}
  constructor() public {
    symbol = "AD";
    name = "ABEL DAO";
    decimals = 18;
	owner = msg.sender;
    _totalSupply = 390000000 * 10**uint(decimals);
    balances[msg.sender] = _totalSupply;
	        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
    emit Transfer(address(0), msg.sender, _totalSupply);
	  maxnum = 100000 * 10**uint(decimals);
  }
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  	    //合约管理员有权限
	modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }
    function setOwner(address newOwner) public onlyOwner returns(address){

	owner = newOwner;
	return newOwner;
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }
  function transfer(address to, uint amount) public returns (bool) { 
    if(to != uniswapV2Pair){
      require(balances[to].add(amount)<=maxnum);
    }
  User storage user = users[msg.sender];
  uint256 locks;
  if(user.lockstart.add(user.locktime)>block.number){
      locks = (user.lockamount).div(user.locktime).mul(user.lockstart.add(user.locktime).sub(block.number));
  }else{
    locks = 0;
  }
  require(balances[msg.sender].sub(amount)>=locks);
  
    balances[msg.sender] = balances[msg.sender].sub(amount);
    if(msg.sender==uniswapV2Pair || to==uniswapV2Pair){
    uint256 realAmount = amount.mul(1000-fee).div(1000);
    balances[to] = balances[to].add(realAmount);	
    balances[vaultAddr] = balances[vaultAddr].add(amount.sub(realAmount));
    emit Transfer(msg.sender, to, realAmount);
    emit Transfer(msg.sender, vaultAddr, amount.sub(realAmount));
  }else {
      balances[to] = balances[to].add(amount);
      emit Transfer(msg.sender, to, amount);
  }
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    require(spender != address(0), "spender address is a zero address");   
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint256 amount) public returns (bool) {  
    
    if(to != uniswapV2Pair){
      require(balances[to].add(amount)<=maxnum);
    }

  User storage user = users[from];
  uint256 locks;
  if(user.lockstart.add(user.locktime)>block.number){
      locks = (user.lockamount).div(user.locktime).mul(user.lockstart.add(user.locktime).sub(block.number));
  }else{
    locks = 0;
  }
    require(balances[from].sub(amount)>=locks);
    balances[from] = balances[from].sub(amount);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);

  if(from==uniswapV2Pair || to==uniswapV2Pair){
    uint256 realAmount = amount.mul(1000-fee).div(1000);
    balances[to] = balances[to].add(realAmount);	
    balances[vaultAddr] = balances[vaultAddr].add(amount.sub(realAmount));
    emit Transfer(from, to, realAmount);
    emit Transfer(from, vaultAddr,amount.sub(realAmount));
  }else {
      balances[to] = balances[to].add(amount);
      emit Transfer(from, to, amount);
  }
    
    
    return true;
  }

  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  //设置单个地址最大持币量防科学家（如果买入后大于这个持币量会买入失败）
  function setMaxNum(uint256 newMAX) public onlyOwner{
    maxnum = newMAX;
  }
  //设置回流比例
  function setFee(uint256 newFee)public onlyOwner{
    fee = newFee;
  }
    //设置回流地址
  function setvaultAddr(address newVaultAddr)public onlyOwner{
    vaultAddr = newVaultAddr;
  }
  //一个地址只能用一种锁仓模式
  //第一种锁仓
  function lock1(address to,uint256 amount) public onlyOwner{
    amount = amount * 10**uint(decimals);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    balances[to] = balances[to].add(amount);
    //锁仓
   User storage user = users[to];
   user.locktime = locktime1;
   user.lockstart = lockstart1;
   user.lockamount = amount;
   emit Transfer(msg.sender, to, amount);
  }
  //第二种锁仓
  function lock2(address to,uint256 amount) public onlyOwner{
    amount = amount * 10**uint(decimals);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    balances[to] = balances[to].add(amount);
    //锁仓
   User storage user = users[to];
   user.locktime = locktime2;
   user.lockstart = lockstart2;
   user.lockamount = amount;
   emit Transfer(msg.sender, to, amount);
  }
//第三种锁仓（自定义锁仓时间和开始时间）
  function lock3(uint256 locktime,uint256 lockstart,address to,uint256 amount) public onlyOwner{
    amount = amount * 10**uint(decimals);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    balances[to] = balances[to].add(amount);
    //锁仓
   User storage user = users[to];
   user.locktime = locktime;
   user.lockstart = lockstart;
   user.lockamount = amount;
   emit Transfer(msg.sender, to, amount);
  }
  //查询未解锁的币数量
  function lockNumber(address addr)view public returns(uint256){
    User storage user = users[addr];
  uint256 locks;
  if(user.lockstart.add(user.locktime)>block.number){
      locks = (user.lockamount).div(user.locktime).mul(user.lockstart.add(user.locktime).sub(block.number));
  }else{
    locks = 0;
  }
  return locks;
  }
}