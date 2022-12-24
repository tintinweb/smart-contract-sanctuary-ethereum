/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
//Ethereum already has a base gas, but it still needs electricity.
contract etc {
  string public constant name="electricty";
  string public constant symbol="ETC";
  uint8 public constant decimals=0;
  uint _totalSupply=10000*1000;
  uint ratio=1000;
  address immutable owner;
  uint immutable initialtime;
  mapping(address=>uint) _balanceof;
  mapping(address=>uint) public ETHback;

  event Transfer(address indexed from, address indexed to, uint256 value);

  constructor(){
    owner=msg.sender;
    initialtime=block.timestamp;
    _balanceof[owner]=_totalSupply;
  }

  function totalSupply() public view returns (uint256) {
      return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256){
      return _balanceof[account];
  }

  function getRatio() public view returns(uint) {
        uint rdays=(block.timestamp-initialtime)/(60*60*24);
        uint r=(1000-int(rdays)>=0)?1000-rdays:0;
        return r;
  }

  function buy() payable public {
    ratio=getRatio();
    if(ratio<=0){
        ETHback[msg.sender]=msg.value;
        return ;
    }
    uint n=msg.value*ratio/(10**18);
    if(n>=1){
        _balanceof[msg.sender]+=n;
        _totalSupply+=n;
    }
  }

  function uphold() payable public {
      require(msg.sender==owner, "onlyowner");
      payable(owner).transfer(address(this).balance);
  }

  function transferFrom(address from, address to, uint amount) public returns (bool) {
      require(amount>0, "0 not require");
      require(_balanceof[from]>=amount, "not enough balance");
      require(to != address(0), "address is 0");
      _balanceof[from]-=amount;
      _balanceof[to]+=amount;
      emit Transfer(from, to, amount);
      return true;
  }

  function transfer(address to, uint amount) public returns (bool){
      address from=msg.sender;
      return transferFrom(from, to, amount);
  }

  function getbackETH() public {
      uint m=ETHback[msg.sender];
      if(m>0){
          payable(msg.sender).transfer(m);
          delete ETHback[msg.sender];
      }
  }
}