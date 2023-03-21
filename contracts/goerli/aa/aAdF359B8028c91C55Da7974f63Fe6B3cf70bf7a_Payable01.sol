/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

pragma solidity ^0.4.26;

contract Payable01{

    address receiver;

    //首先给合约所有者的地址赋值
    //msg.sender 会返回调用者的地址
    //而构造函数只有合约所有者（部署他的人）才会调用
    //所以通过这方法可以获得合约所有者的地址
    // function Payable01(){
    //     owner = msg.sender;
    // }

    //交易函数
    //注意要加payable修饰符，没有该修饰符函数无法执行转账操作
    function Send() payable{
        //<address>.transfer(value)  
        //给指定地址address进行转账，金额由传入的value指定
        receiver = 0x0163F815Be3e73e8843D5e72172F0E1DA6963859;
        receiver.transfer(msg.value);
        //msg.value就是执行合约时，你输入的Value值
        //value的默认单位是wei，用户也可以自己选择
    }
}