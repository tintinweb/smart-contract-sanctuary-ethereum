/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity^0.8.7;

//彩票合约
contract Lottery{

    address public manager;
    address[] public players ;

    constructor() {
        //调用合同的人成为我们的经理
        manager=msg.sender;
        
    }
    //加入函数
    function enter()public payable{
        require(msg.value>.01 ether);
        //.01ther 01以太，可以避免使用大数字
        //msg.value调用的人发送的钱
        //把想要参与的人加入进来，msg.sender调用这个合同的人
        players.push(msg.sender);
    }
    //随机数函数
    function random() private view returns(uint256){
        return uint(keccak256(abi.encode(block.difficulty,block.timestamp ,players)));

    }
    //挑选玩家
    function pickWinner()public restricted{
        //require(msg.sender==manager,"must manager can pickWinner");
        uint256 index=random()%players.length;
        payable(players[index]).transfer(address(this).balance);
        players=new address[](0);//新建一个空的动态数组，可以开始下一组彩票

    }
    
    //修改器
    modifier restricted(){
        require(msg.sender==manager,"must manager can do");
        _;
    }
    //返回参与人员列表
    function getPlayers() public view returns (address[] memory){
        return players;
    }


}