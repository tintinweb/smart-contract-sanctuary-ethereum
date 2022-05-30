/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.4.2;

contract crowd_funding {


    //捐赠者的结构
    struct Contributor {
        address Contributor_address; //投资者的地址
        uint Contributor_money; //投资者的投资金额
    }

    //接受者的结构
    struct Receiver {
        address Receiver_address; //接受者的地址
        uint goal; //募集的目标金额
        uint money; //当前的金额
        uint Contributor_amount; //捐赠者参与的人数
        mapping(uint => Contributor) map;//通过id和捐赠者进行映射绑定
    }

    uint public ReceiverID; //接受者的ID
    mapping(uint => Receiver) Receiver_map;//通过ID和接受者进行绑定


    //创建一个新众筹活动
    function creat_New_Funding_Campaign(address _address, uint _goal) public {
        ReceiverID++;
        Receiver_map[ReceiverID] = Receiver(_address,_goal,0,0);


    }

    //发起捐赠
    function contribute(address Newaddress, uint _ReceiverID) public payable {
        //通过ID获取接收者对象
        Receiver storage R = Receiver_map[_ReceiverID];
        //当前接受者金额加上获赠的金额
        R.money += msg.value;
        //捐赠人数加1
        R.Contributor_amount++;
        //将接受者ID与捐赠者绑定在一起
        R.map[R.Contributor_amount] = Contributor(Newaddress,msg.value);
    }


    //判断众筹是否完成目标并

    function Iscomplete(uint _ReceiverID) public  returns (bool) {
        //通过ID获取对象
        Receiver storage R = Receiver_map[_ReceiverID];
        //判断筹集资金是否到达目标值
        if (R.money >= R.goal) {
            //将筹集到的自己发送到接受者合约的地址
            R.Receiver_address.send(R.money);
            return true;
        }

        return false;
    }


}