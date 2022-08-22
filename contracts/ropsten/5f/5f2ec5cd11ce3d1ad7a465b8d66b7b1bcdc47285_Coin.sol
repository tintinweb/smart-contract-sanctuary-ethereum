/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Coin{

    address public minter;

    mapping(address=>uint) public balances;
    
    struct User{
        address  uname;
        uint  umoney;
    }

    User[] public userlist;

    event Sent(address from,address to, uint amount);




    function mint(address reveiver,uint amount) public {
        if(msg.sender!=minter) return;

        balances[reveiver] += amount;

    }

    struct BlockInfo{
        address  coinbase;
        uint  difficulty;
        uint  gaslimit;
        uint  number;

    }

    struct MsgInfo{
        bytes  data;
        uint256  gas;
        address  sender;
        uint  value;
    }

    struct OtherInfo{
        uint  now;
        uint  gasprice;
        address  origin;
    }


    function test1() public view returns(BlockInfo memory ){
        
        return BlockInfo(block.coinbase,block.difficulty,block.gaslimit,block.number);
    }

    function test2() public payable returns(MsgInfo memory ){
        return MsgInfo(msg.data,gasleft(),msg.sender,msg.value);
    }

    function test3() public view returns(OtherInfo memory){
        
        return OtherInfo(block.timestamp,tx.gasprice,tx.origin);
    }



    function sent(address to,uint amount) public {
        if(balances[msg.sender]<amount) return;

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Sent(msg.sender,to,amount);
    }




}