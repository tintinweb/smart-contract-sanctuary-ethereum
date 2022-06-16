/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

/*        代码中各部分顺序如下：
            Pragma 语句
            Import 语句
            Interface
            库
            Contract
        在Interface、库或Contract中，各部分顺序应为：
            Type declaration / 类型声明
            State variable / 状态变量
            Event / 事件
            Function / 函数
*/


pragma solidity ^0.4.16;

contract test{

    string public message;
    address public manager;//合约的拥有者
    address public caller;//合约的调用者

    //地址映射哈希表mapping
    mapping(address => uint256) public list;

    //定义事件
    event Theevent(address,uint);

    //初始化
    constructor () public {
        manager = msg.sender;
    }

    function setMessage(string newMessage) public{
        caller = msg.sender;
        //合约拥有者与调用者不同时，抛出异常
        assert(msg.sender == manager);
        message = newMessage;

    }
    function getMessage() public constant returns(string){
        return message;
    }
    function TestTheevent() public payable{
        emit Theevent(msg.sender,msg.value);
    }
    

    function () public payable{

    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;//合约本身的余额
    }

    function getBalance() public view returns(uint){
        return caller.balance;
    }

    //转账
    function TransferClient() public payable {
        //如果转账不是（）则失败，正确则加入维护的mapping中
        assert(100 == msg.value);
        list[msg.sender] = msg.value;
        address(this).transfer(msg.value);
    }
    //合约销毁
    function kill() private {
        require(manager == msg.sender);
        selfdestruct(msg.sender);
    }
}


// //使用访问函数 is是继承
// contract test1 is test{
//     function getValue() public returns(string){
//         test t1 = new test();
//         return t1.message();
//     }
// }