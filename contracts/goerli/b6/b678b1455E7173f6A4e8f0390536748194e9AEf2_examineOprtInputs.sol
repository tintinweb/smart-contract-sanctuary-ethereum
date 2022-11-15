// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract examineOprtInputs {
    // 事件：记录记录发起人地址，区块高度，数组位置
    event createLog(address indexed sender, uint blocknumber, uint indexed index);

    struct Input {//定义管控信息录入结构
        string productCode;//产品对象编号
        uint256 structureType;//结构类型参数
        string context;//管控内容文本
        bool isDone;//管控执行状态
        string examineTime;//管控执行时间范围
    }

    // 结构体数组
    Input[] public Inputs;

    // 记录结构体，传参如["aaa",123,"bb",true,"ccc"]
    function create(Input memory todo1) public{
        Inputs.push(todo1);
        emit createLog(msg.sender, block.number, (Inputs.length - 1));
    }

    // 验证结构体, 传参如["aaa",123,"bb",true,"ccc"],0
    function verify(Input memory todo2, uint _index) public view returns (bool _result) {
        if(keccak256(abi.encode(Inputs[_index])) == keccak256(abi.encode(todo2))){
            return true;
        } else {
            return false;
            }
        }
}