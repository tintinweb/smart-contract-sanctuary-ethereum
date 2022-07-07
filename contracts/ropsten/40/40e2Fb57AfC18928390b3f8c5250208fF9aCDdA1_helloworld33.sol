/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

//指定solidy编译器版本，版本标识符
pragma solidity ^0.4.25;
 
//关键字 contract 跟java的class一样  智能合约名称是helloworld
contract helloworld33 {
    //状态变量
    //string 是数据类型，message是成员变量，在整个智能合约生命周期都可以访问
    //public 是访问修饰符，是storage类型的变量，成员变量和是全局变量
    string public message;
    //address 是地址类型，
    address public manager;
    
    //构造函数,这里在合约部署时将合约所有者传入
    constructor () public {
        manager = msg.sender; 
    }
   //函数以function开头
    function setMessage (string _message) public {
        //局部变量
        string memory tmp;
        tmp = _message;
        message = tmp;
    }
    //view是修饰符，表示该函数仅读取成员变量，不做修改
    function getMessage() public view returns (string) {
        return message;
    }
}