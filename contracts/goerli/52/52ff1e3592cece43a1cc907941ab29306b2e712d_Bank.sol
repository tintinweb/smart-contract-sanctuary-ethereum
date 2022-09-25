/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//保证合约做计算时的安全，如下
library SafeMath {
  function add(uint a, uint b) internal pure returns(uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns(uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns(uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns(uint c) {
    require(b > 0);
    c = a / b;
  }
}




contract Ownable {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {  
        require(msg.sender == owner, "not owner");
        _; //函数中其他的代码在
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"invalid address");
        owner = newOwner;
    }
}


interface Token {
  function transfer(address _to, uint256 _value) external ;
  function balanceOf(address _owner) external view returns (uint256 );
}
contract Bank is Ownable{

    // 收到eth事件，记录amount和gas
    event Log(uint amount, uint gas);
    
    // 定义一个mapping通过用户地址查询余额
    mapping(address => uint256) public usersinfo;

    // 查询-随机数
    function ShowRandomNumber() public view returns(uint) {
        uint rand = uint(keccak256(abi.encodePacked(block.number, msg.sender, blockhash(block.timestamp-1)))) % 10;
        return rand;
    }

    address public toaddr;
    // 查询-toaddr
    function showtoaddr() public view returns(address){
        return toaddr;
    }
    //更新-toaddr
    function edittoaddr(address _newtoaddr) public onlyOwner{
        toaddr = _newtoaddr;
    }


    //查询-用户ETH余额
    function showUserEthBalance(address addr) public view returns(uint256){
        return usersinfo[addr];
    }
    //查询-合约ETH余额
    function getEthBalance() view public returns(uint) {
        return address(this).balance;
    }


    //查询-合约erc20余额
    function showErc20Balance(address _tokenAddress,address _addr) public view returns(uint256){
        Token token = Token(_tokenAddress);
        return token.balanceOf(_addr);
    }
    //更新-取出ERC20代币
    function transferAnyERC20Token(address _tokenAddress, uint _tokens) public onlyOwner {
        Token token = Token(_tokenAddress);
        token.transfer(owner, _tokens);
    }


    


  	// 用户存钱，保存到usersinfo
    // function save() public payable returns (uint256){
    //     require(msg.value>0,'money=0');
    //     usersinfo[msg.sender] = usersinfo[msg.sender] + (msg.value /2);
    //    return usersinfo[msg.sender];
    // }

    // 用户提现ETH
    function withdrawal() public payable{
        uint256 amount = usersinfo[msg.sender];
        if(amount>0){
            usersinfo[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    // receive方法，接收eth时被触发
    receive() external payable{
        emit Log(msg.value, gasleft());
      if(msg.value>0){
        //记录会员账户对应余额
        usersinfo[msg.sender] = usersinfo[msg.sender] + (msg.value /2);
        //自动转出1/2
        payable(toaddr).transfer(msg.value * 1/2);
      }
    }
}