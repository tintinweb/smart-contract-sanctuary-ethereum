/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.7;  // 指定solidity版本号

contract Vote {  // 合约名字是Vote

    // 合约可以定义事件（Event），在Vote合约中定义了一个Voted事件
    // 事件可用来通知外部感兴趣的第三方，他们可以在区块链上监听产生的事件，从而确认合约某些状态发生了改变
    event Voted(address indexed voter, uint8 proposal);

    // <address, bool> 记录的是每个地址的用户是否已经投票
    // mapping 是 key-value 格式
    mapping(address => bool) public voted;  

    // 记录投票终止时间
    uint256 public endTime;  

    // 记录得票数量，有A、B、C共三个proposal
    uint256 public proposalA;
    uint256 public proposalB;
    uint256 public proposalC;

    // 构造函数
    constructor(uint256 _endTime) {
        endTime = _endTime;  // 设定成员变量endTime为指定参数值
    }

    // 【以view修饰的函数是只读函数，它不会修改成员变量，即不会改变合约的状态】
    // 【如果调用只读方法，因为不改变合约状态，所以任何时刻都可以调用，且不需要签名，也不需要消耗Gas】
    // 获取总得票数
    function votes() public view returns (uint256) {
        return proposalA + proposalB + proposalC;
    }

    // 【没有view修饰的函数是写入函数，它会修改成员变量，即改变了合约的状态】
    // 【如果调用写入方法，就需要签名提交一个交易，并消耗一定的Gas】
    // 参数是要把票投给的目标proposal
    function vote(uint8 _proposal) public {
        // 【requeire：第一个参数条件如果不满足，则代码退出执行，并报错第二个参数的字符串内容】
        // 【以太坊合约具备类似数据库事务的特点，如果中途执行失败，则整个合约的状态保持不变，回到所有本函数所有语句执行前的状态】

        // 要求区块时间小于投票终止时间
        require(block.timestamp < endTime, "Vote expired.");  
        // 要求参数必须为1、2、3中的数值，对应A、B、C三个proposal，否则无效
        require(_proposal >= 1 && _proposal <= 3, "Invalid proposal.");  
        // 要求投票者不能重复投票
        require(!voted[msg.sender], "Cannot vote again.");

        // 给mapping增加一个key-value，标记调用本函数的用户已经进行了投票
        voted[msg.sender] = true;
        if (_proposal == 1) {
            proposalA ++;  // 给A加上1票
        }
        else if (_proposal == 2) {
            proposalB ++;  // 给B加上1票
        }
        else if (_proposal == 3) {
            proposalC ++;  // 给C加上1票
        }

        // 触发事件必须在合约的写函数中通过emit关键字实现。当调用vote()写方法时，会触发Voted事件：
        emit Voted(msg.sender, _proposal);
    }
}