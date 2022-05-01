/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// 投注合约需要包含:期数、投注、开奖、退奖、奖池
// 关键要素如下
// 1.一个mapping映射，一个参与者地址对应一个投注金额
// 2.参与者的投注金额统一打入奖池
// 3.项目方每期无论结果都将自动获取奖池中2%的代币
// 4.未在规定时间内开奖，参与者可调用退款

contract caipiaobet{
    // uint public round = 1 ;  //期数
    string public name;
    uint public startTime ;  //投注开始时间
    uint public endTime ;    //投注结束时间
    uint public drawTime ;   //开奖时间
    uint public refundTime ; //未执行开奖后的可退款时间
    address payable public winNer ;   //每期中奖者地址
    uint public winNum ;     //中奖者编号
    address payable[] public joiner;   //当前期的参与者，每期结束后清空
    mapping(address=>uint) public participant ;  //投注地址和金额，每期开奖后清空
    uint public pool = 0 ;    //奖池金额
    address payable public manager ;  //管理员
    bool public isdrawPrice ;  //判断是否已开奖
    event Touzhu (address from,uint value) ;  
    event drawPriceToWinner (address winner,uint value);
    event drawPriceToManager (address Manager,uint Value);
    constructor(string memory _name) {
        manager = payable(msg.sender);
        //block.timestamp为操作的当前时间
        startTime = block.timestamp + 15 seconds;
        endTime = block.timestamp + 315 seconds;
        drawTime = block.timestamp + 330 seconds;
        refundTime = block.timestamp + 450 seconds;
        name = _name;
    }


    //投注函数
    function touzhu() public payable{
        //管理员不能投注
        require(payable(msg.sender)!=manager,"Sorry,Manager can't join");
        //判断投注时间是否在规定时间内
        require(block.timestamp >= startTime,"Sorry,Time has't come");
        require(block.timestamp <= endTime,"Sorry,Time has passed");
        uint d = msg.value;
        if (d > 0) {
            payable(address(this)).transfer(d);    //用户投注
            emit Touzhu(msg.sender,d);
            pool += d;                             //奖池金额增加      
            //如果该地址的投入金额为0，那么在参与者数组中追加该地址
            if(participant[msg.sender] == 0){
                joiner.push(payable(msg.sender));
            }
            participant[msg.sender] += d; //存储用户投注金额
        } else {
            //如果投注金额不大于0，则报错
            revert("Please input more than 0 ether");
        }
    }
    
    //开奖函数
    function drawPrice() public{
        //判断是否到开奖时间
        require(block.timestamp >= drawTime,"Sorry,drawTime has't come");
        //判断开奖者是否为管理员
        require(payable(msg.sender) == manager,"Sorry,you have no right to drawPrice");
        //判断是否已过规定开奖时间
        require(block.timestamp < refundTime,"Sorry,you did't draw the prize in time");
        //判断是否已开过奖
        require(isdrawPrice == false,"Sorry,you have already draw the prize");
        if (joiner.length != 0){
            //获取随机数
            bytes memory randomInfo = abi.encodePacked(block.timestamp,block.difficulty,joiner.length); 
            bytes32 randomHash = keccak256(randomInfo);
            //利用随机数获取中奖者索引
            winNum = uint(randomHash)%joiner.length;
            winNer = payable(joiner[winNum]);
            //中奖者获取奖金
            uint d = address(this).balance/100*98 ;
            payable(winNer).transfer(address(this).balance/100*98);
            emit drawPriceToWinner(winNer,d);
            //管理员抽水
            uint b = address(this).balance;
            payable(manager).transfer(address(this).balance);
            emit drawPriceToManager(manager,b);
            pool = 0 ;  //存储数据池清空
            // round++;    //轮数+1
            isdrawPrice = true;
        } else {
            // round++;
        }
    }

    //后备接收函数，保证合约地址能接受以太坊
    receive() external payable{}

    //退款函数
    function refund() public {
        //用户只有在管理员未在指定时间内开奖时才可执行此函数
        require(block.timestamp >= refundTime,"Sorry,the refundTime has't come");
        if(participant[msg.sender] > 0) {
            //在合约地址中取款
            payable(msg.sender).transfer(participant[msg.sender]);
            pool -= participant[msg.sender];  //一定要在执行下一行语句前先清掉该地址在池子中的额度
            delete participant[msg.sender];   //取完款后删除对应键值
        } else {
            //如果未投注进行调用或取完款再次调用，都会报错
            revert("Sorry,you have no right to refund,maybe you have refunded");
        }
    } 

    function deleteArray() public {
        require(msg.sender == manager,"Sorry,you have no right to delete");
        require(isdrawPrice == true,"Sorry,Please draw the price first");
        for (uint i = 0 ; i < joiner.length ; i++) {
            //无法直接删除映射，采用数组索引
            delete participant[joiner[i]];
        }
        delete joiner;  //必须等映射删除完毕再删除数组
    }

    //获取合约实时以太坊余额
    function getContractBalance() public view returns(uint){
        uint d = address(this).balance;
        return d;
    }
}