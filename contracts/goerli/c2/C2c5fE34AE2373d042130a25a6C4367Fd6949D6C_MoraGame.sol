/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


// 猜拳合约游戏
contract MoraGame {
    address _owner; // 合约部署者
    uint private randNonce = 0; // 调用随机数生成的次数

    constructor() payable {
        _owner = msg.sender;
    }

    // 限制提现对象为合约部署者
    modifier onlyOwner() {
        require( msg.sender == _owner, "only owner can withdraw." );
        _;
    }

    // 限制输入值
    modifier gameLimit(uint gesture) {
        // 质押金额必须大于零
        require( msg.value > 0, "value must more than 0." );
        // 质押金额必须大于合约已有金额，合约余额需减去调用该方法时的质押金额
        require( msg.value <= (address(this).balance - msg.value), "value must less than contract's balance." );
        // 手势必须为1,2,3中的其中一种
        require( gesture == 1 || gesture == 2 || gesture == 3, "gesture must 1,2,3, mean shitou,jiandao,bu." );
        _;
    }

    // 定义事件
    event GetResult(address indexed who, uint gesture, uint _gesture, bool result, uint value);

    // 提现
    function getRan(uint start, uint end) private returns (uint) {
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % end + start;
        randNonce++;
        return random;
    }

    //  开始游戏
    function startGame(uint gesture) public payable gameLimit(gesture) returns (bool) {
        bool result; // false, true   --->   输，赢
        uint _gesture; // 1, 2, 3   --->   剪刀，石头，布
        int diff; // 输（-2, 1），平（0），赢（-1, 2）
        while (true) {
            _gesture = getRan(1, 3);
            diff = int(_gesture - gesture);
            if (diff == -2 || diff == 1) {
                result = true;
                break;
            } else if (diff == -1 || diff == 2) {
                result = false;
                break;
            }
        }
        if (result == true) {
            payable(msg.sender).transfer(msg.value * 2);
        }
        // 触发事件
        emit GetResult(msg.sender, gesture, _gesture, result, msg.value);
        return result;
    }

    // 充值
    function deposit() external payable {}

    // 提现
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // 获取合约余额
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}