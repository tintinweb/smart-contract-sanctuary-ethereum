/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity ^0.8.0;

contract accept{

    address owner;//管理者地址

    constructor () {//构造函数，合约创建时执行
        owner = msg.sender;//把合约创建者的地址设置为管理者地址
    }

    receive() external payable {}//合约接收转账

    //销毁合约，销毁后合约上的余额会发送给调用者，且只能使用一次，之后合约收到的余额无法在转出，因为销毁的合约无法销毁第二次
    function claim() public{
        if (owner == msg.sender) { // 检查谁在调用
            selfdestruct(payable(owner)); // 销毁合约
        }
    }
    
}