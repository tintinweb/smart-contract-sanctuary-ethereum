/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
//函数签名也叫函数的选择器，用来代表一个合约中虚拟机是怎么找到函数的
//在智能合约的虚拟机中，调用一个函数就要用函数的选择器来区分函数，所以可以出现同源函数，只要参数类型不同，名称可以是相同的

//----------使用AbiEncode的getSelector函数，输入"transfer(address,uint256)"即可得到哈希值的bytes4类型值0xa9059cbb----------//

contract AbiEncode{
    address public owner;
    uint public a;
        constructor() public {
        owner = msg.sender;//可以用来查看调用者的地址
    }
   
    event Log/*事件*/(bytes data/*bytes类型*/);
    function transferFromOwner/*函数类型*/(address _to/*地址类型*/,uint _amount/*uint类型*/)public payable/*外部可视*/{
        emit Log(msg.data/*消息的数据*/);//呼叫一个函数的数据由两部分组成，第一部分是选择器，也叫函数的签名，第二部分是函数的参数
        //0xa9059cbb 8个字符占4个字节（位）  这个函数签名是通过将函数名和参数类型打包在一起进行哈希值，然后取哈希值的前4位16进制数字得到的结果
        //0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4  _to（地址类型）
        //000000000000000000000000000000000000000000000000000000000000000b  _amount（uint类型）输入成了11，装换为16进制的结果
        require(msg.sender==owner,unicode"你不是owner，无权调用此函数");
    }

   function transfer/*函数类型*/(address _to/*地址类型*/,uint _amount/*uint类型*/)public payable/*外部可视*/{
        emit Log(msg.data/*消息的数据*/);//呼叫一个函数的数据由两部分组成，第一部分是选择器，也叫函数的签名，第二部分是函数的参数
        //0xa9059cbb 8个字符占4个字节（位）  这个函数签名是通过将函数名和参数类型打包在一起进行哈希值，然后取哈希值的前4位16进制数字得到的结果
        //0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4  _to（地址类型）
        //000000000000000000000000000000000000000000000000000000000000000b  _amount（uint类型）输入成了11，装换为16进制的结果
        // require(msg.sender==owner,unicode"你不是owner，无权调用此函数");
    }

    function changeOwner/*函数类型*/()public payable/*外部可视*/{
        require(msg.sender==owner,unicode"你不是owner，无权调用此函数");
        owner=msg.sender;
    }


    bytes public data;//写这个状态变量用于装载返回的_data数据
    function callFoo(address _test)external payable{//外部可见，是一个写入方法  这个函数发送了主币，而合约本身是没有主币的，需要用payable方法
        (bool success,bytes memory _data)=_test.call{value:111,gas:50000}(abi.encodeWithSignature( /*  可以给呼叫foo这个函数的同时发送一个主币的数量，在call后面加上{}，里面写一个value：111，然后还可以带上一些信息，比如
        这次函数的时候带着多少个gas */
            'foo(string,uint256)','call foo',123
        ));
       /*  将_testd地址传进来就可以进行call操作了，并不需要把上个合约当做类型引用进来，在call的()中要写我们要调用哪个合约
        的函数，而这个合约的函数我们在这里必须要采用编码的形式传递进来，这是一个abi编码，这个abi编码首先要函数的名称加上它
        的参数类型以字符串的形式来传递进去，这里uint必须要写成uint256才行，参数的名称（_message,_x）和参数的存储位置（memory）都不用写
        接下来把参数填进去，第一个参数时候字符串类型，我们要加上一个""加上一个字符串，下一个是数字写上123    
        我们整理下缩进， 可以有一些缩进，这样的调用方法会有2个返回值，第一个返回值是bool值，用来标记调用是否成功，第二个返回值是data，是
        bytes类型的，用来装在foo这个函数的所有返回值，都会装载在data这个bytes里面 */
        require(success,'call failed');//然后我们确认下返回的第一个bool值是否成功，如果失败给一个报错，
        data=_data;//将函数调用过后的_data数据赋值给状态变量data 
    }
    function callDoesNotExit(address _test)external{
       (bool success,)=_test.call{value:111,gas:50000}(abi.encodeWithSignature('doesNotExist()'));
       require(success,'call failed');
    }
}